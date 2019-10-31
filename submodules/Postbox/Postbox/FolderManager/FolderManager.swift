//
//  FolderManager.swift
//  Postbox
//
//  Created by Valeriy Mikholapov on 16/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import iMeLib

final class FolderManager {

    // MARK: - In-memory cache

    private var updateTokens: [WeakRef<UpdateToken>] = []

    private var cachedFolders: [Folder] = [] {
        didSet { sendFoldersToAllObservers(folders) }
    }

    private var cachedLastMessages: [Folder.Id: Message] = [:] {
        didSet { sendFoldersToAllObservers(folders) }
    }

    private var cachedUnreadCounts: [Folder.Id: UInt] = [:] {
        didSet { sendFoldersToAllObservers(folders) }
    }

    // MARK: - Components

    private let folderStorage: FolderStorage = .shared
    private let idGenerator: IdGenerator = .shared

    // MARK: -

    static var shared: FolderManager = .init()

    var folders: [Folder] {
        return cachedFolders
            .map {
                $0.lastMessage = cachedLastMessages[$0.folderId]
                $0.unreadCount = cachedUnreadCounts[$0.folderId]
                return $0
            }
            .sorted {
                guard
                    let leftTimestamp = $0.lastMessage?.timestamp,
                    let rightTimestamp = $1.lastMessage?.timestamp
                else { return false }

                return leftTimestamp < rightTimestamp
        }
    }

    private init() {
        folderStorage.folderListUpdate = { [weak self] in
            self?.cachedFolders = $0
        }
    }

    // MARK: - CRUD methods

    func folder(with id: Folder.Id) -> Folder? {
        return cachedFolders.first { $0.folderId == id }
    }

    func createFolder(with name: String, peerIds: [PeerId]) {
        let result = folderStorage.create(
            folder: .init(
                folderId: idGenerator.generateId(),
                name: name,
                peerIds: peerIds,
                pinningIndex: nil
            )
        )

        if case let .failure(error) = result {
            // TODO: Handle error
            print(error)
        }
    }

    func delete(folderWithId id: Folder.Id) {
        let result = folderStorage.delete(folderWithId: id)

        if case let .failure(error) = result {
            // TODO: Handle error
            print(error)
        }
    }

    func rename(folder: Folder, reloadClosure: @escaping () -> Void) {
        folderStorage.rename(folder: folder, updateClosure: reloadClosure)
    }

    func update(folder: Folder) {
        folderStorage.update(folder: folder)
    }

    // MARK: -

    func isIncludedInAnyFolder(peerId: PeerId) -> Bool {
        return cachedFolders.first { $0.peerIds.contains(peerId) } != nil
    }

    func subscribe(onUpdates updateClosure: @escaping UpdateClosure) -> UpdateToken {
        let token = UpdateToken(folderManager: self, updateClosure: updateClosure)
        updateTokens.append(WeakRef(value: token))
        updateClosure(folders)
        return token
    }

    func togglePin(ofFolderWithId id: Folder.Id) throws {
        guard let folder = folder(with: id) else {
            return assertionFailure("There is no folder with id (\(id)).")
        }

        let pinnedFolders = cachedFolders.filter { $0.pinningIndex != nil }
        if let pinningIndex = folder.pinningIndex {
            let foldersToUpdate = pinnedFolders
                .filter { $0.pinningIndex.map { $0 > pinningIndex } ?? false }

            foldersToUpdate.forEach {
                $0.pinningIndex = $0.pinningIndex.map { $0 - 1 }
            }
            
            folder.pinningIndex = nil
        } else {
            let maxPinningIndex = pinnedFolders
                .lazy
                .compactMap { $0.pinningIndex }
                .max() ?? 0

            guard maxPinningIndex < 4 else {
                // TODO: Make normal error throwing.
                throw NSError()
            }

            pinnedFolders.forEach {
                $0.pinningIndex = $0.pinningIndex.map { $0 + 1 }
            }

            folder.pinningIndex = 0
        }


        folderStorage.update(folder: folder)
    }

    func process(deletedPeerWithId id: PeerId) -> Bool {
        let foldersToUpdate = folders
            .lazy
            .filter { $0.peerIds.contains(id) }
            .map { (folder) -> Folder in
                folder.peerIds.remove(id)
                return folder
            }
            .collect()

        guard !foldersToUpdate.isEmpty else { return false }

        folderStorage.update(folders: foldersToUpdate)

        return true
    }

    func process(readStates: [(chat: Peer, readState: CombinedPeerReadState)]) {
        let unreadCountsForPeer = readStates
            .lazy
            .map { ($0.id, UInt($1.count)) }
            .dict(+)

        cachedUnreadCounts = cachedFolders
            .map { folder in
                (
                    key: folder.folderId,
                    value: folder.peerIds.reduce(0) { $0 + unreadCountsForPeer[$1].or(0) }
                )
            }.collect()
    }

    func process(messages: [(chat: Peer, message: Message)]) {
        let filteredMessages: [PeerId: (chat: Peer, message: Message)] = messages.reduce(into: [:]) {
            if let oldValue = $0[$1.chat.id] {
                guard oldValue.message.timestamp < $1.message.timestamp else { return }
                $0[$1.chat.id] = $1
            } else {
                $0[$1.chat.id] = $1
            }
        }

        cachedFolders.forEach {
            if let id = $0.lastMessage?.author?.id, !$0.peerIds.contains(id) {
                $0.lastMessage = nil
            }
        }

        let updatedFolders: [Folder] = folderStorage.getAllFolders()
            .compactMap { folder in
                folder.peerIds
                    .lazy
                    .compactMap { filteredMessages[$0]?.message }
                    .reduce(folder.lastMessage) { prev, new in
                        prev.map { $0.timestamp < new.timestamp ? new : $0 } ?? new
                    }
                    .map {
                        folder.lastMessage = $0
                        return folder
                    }
            }

        var updatedCachedLastMessages = cachedLastMessages
        updatedFolders.forEach {
            updatedCachedLastMessages[$0.folderId] = $0.lastMessage?.withUpdatedPeer($0)
        }
        cachedLastMessages = updatedCachedLastMessages
    }

    // MARK: - Token operations

    fileprivate func delete(token: UpdateToken) {
        updateTokens.removeAll { $0.value === self }
    }

    private func sendFoldersToAllObservers(_ folders: [Folder]) {
        updateTokens.forEach {
            $0.value?.updateClosure(folders)
        }
    }

}

// MARK: - Inner types

extension FolderManager {

    typealias UpdateClosure = ([Folder]) -> Void

    /// Allows to store weak references in collections.
    final private class WeakRef<T: AnyObject> {
        weak var value: T?

        init(value: T) {
            self.value = value
        }
    }

    final class UpdateToken {
        private var folderManager: FolderManager?
        fileprivate var updateClosure: UpdateClosure

        init(folderManager: FolderManager, updateClosure: @escaping UpdateClosure) {
            self.folderManager = folderManager
            self.updateClosure = updateClosure
        }

        deinit {
            invalidate()
        }

        func invalidate() {
            folderManager?.delete(token: self)
        }
    }

}

// MARK: -

private extension Message {

    func withUpdatedPeer(_ peer: Peer) -> Message {
        let id = MessageId(peerId: peer.id, namespace: self.id.namespace, id: self.id.id)
        var peers = self.peers
        peers[peer.id] = peer

        return Message(
            stableId: self.stableId,
            stableVersion: self.stableVersion,
            id: id,
            globallyUniqueId: self.globallyUniqueId,
            groupingKey: self.groupingKey,
            groupInfo: self.groupInfo,
            timestamp: self.timestamp,
            flags: self.flags,
            tags: self.tags,
            globalTags: self.globalTags,
            localTags: self.localTags,
            forwardInfo: self.forwardInfo,
            author: self.author,
            text: self.text,
            attributes: self.attributes,
            media: self.media,
            peers: peers,
            associatedMessages: self.associatedMessages,
            associatedMessageIds: self.associatedMessageIds
        )
    }

}
