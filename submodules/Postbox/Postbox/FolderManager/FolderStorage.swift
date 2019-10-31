//
//  FolderStorage.swift
//  Postbox
//
//  Created by Valeriy Mikholapov on 16/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import CoreData

final class FolderStorage {

    var folderListUpdate: (([Folder]) -> Void)? {
        didSet {
            folderListUpdate?(getAllFolders())
        }
    }

    static var shared: FolderStorage = .init()

    private lazy var persistenceContainer: NSPersistentContainer = {
        guard let container = NSPersistentContainer(type: ManagedFolder.self) else {
            fatalError("Failed to initilise container.")
        }
        
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    private var context: NSManagedObjectContext {
        return persistenceContainer.viewContext
    }

    private var cachedFolders: [Int32: ManagedFolder] = [:] {
        didSet {
            folderListUpdate?(getAllFolders())
        }
    }

    private init() {
        observeAppTermination()
        fetchFromDisk()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func getAllFolders() -> [Folder] {
        return cachedFolders.values.compactMap { $0.toPlainEntity() }
    }

    func create(folder: Folder) -> Result<Void> {
        guard cachedFolders[folder.folderId] == nil else {
            return .failure(Error.failedToSave)
        }

        let managedFolder = ManagedFolder(context: context, plainEntity: folder)

        do {
            try self.context.save()
            cachedFolders[folder.folderId] = managedFolder
            return .success(())
        } catch let error as NSError {
            print(error)
            return .failure(error)
        }
    }

    // FIXME: Workaroud for problem with not changing name on folder list tab.
    func rename(folder: Folder, updateClosure: () -> Void) {
        guard let managedFolder = cachedFolders[folder.folderId] else {
            return assertionFailure("Folder \(folder.name) either does not exist or in-memory cache was corrupted.")
        }

        syncronise(managedFolder: managedFolder, with: folder)

        folderListUpdate?([])
        updateClosure()
        folderListUpdate?(getAllFolders())

        do {
            try context.save()
        } catch {
            print(error)
        }
    }

    /// Udpates folder.
    ///
    /// - Note: If `peerIds` set contains no elements for the folder, it'll be removed instead of being updated.
    ///
    /// - Parameter folders: Folder that were updated.
    func update(folder: Folder) {
        guard let managedFolder = cachedFolders[folder.folderId] else {
            return assertionFailure("Folder \(folder.name) either does not exist or in-memory cache was corrupted.")
        }

        syncronise(managedFolder: managedFolder, with: folder)

        if folder.peerIds.isEmpty {
            context.delete(managedFolder)
            cachedFolders.removeValue(forKey: folder.folderId)
        }

        folderListUpdate?(getAllFolders())

        do {
            try context.save()
        } catch {
            print(error)
        }
    }

    /// Udpates folders.
    ///
    /// - Note: If `peerIds` set contains no elements for certain folder, it'll be removed instead of being updated.
    ///
    /// - Parameter folders: Folders that were updated.
    func update(folders: [Folder]) {
        guard !folders.isEmpty else { return }

        var foldersToDelete: [ManagedFolder] = []
        var cachedFolders = self.cachedFolders

        for folder in folders {
            guard let managedFolder = cachedFolders[folder.folderId] else {
                assertionFailure("Folder \(folder.name) either does not exist or in-memory cache was corrupted.")
                continue
            }

            syncronise(managedFolder: managedFolder, with: folder)

            if managedFolder.peerIds.isEmpty {
                foldersToDelete.append(managedFolder)
            }
        }

        self.cachedFolders = cachedFolders
            .filter { !$0.value.peerIds.isEmpty }

        foldersToDelete.forEach(context.delete)

        do {
            try context.save()
        } catch {
            print(error)
        }
    }

    func delete(folderWithId id: Folder.Id) -> Result<Void> {
        guard let managedObject = cachedFolders[id] else {
            return .failure(Error.failedToRetrieve)
        }

        delete(managedFolder: managedObject)

        do {
            try context.save()
        } catch {
            print(error)
        }

        return .success(())
    }

    // MARK: - Initialisation

    private func fetchFromDisk() {
        let fetchRequest = NSFetchRequest<ManagedFolder>(entityName: String(describing: ManagedFolder.self))
        do {
            self.cachedFolders = try .init(uniqueKeysWithValues: context.fetch(fetchRequest).map { ($0.id, $0) })
        } catch {
            print(error)
        }
    }

    private func observeAppTermination() {
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] notification in
            guard let context = self?.context, context.hasChanges else { return }

            do {
                try context.save()
            } catch {
                print(error)
            }
        }
    }

    // MARK: - CRUD helpers

    private func syncronise(managedFolder: ManagedFolder, with folder: Folder) {
        let peerIdsToDelete = managedFolder.peerIds
            .filter { !folder.peerIds.contains($0.toPlainEntity()) }

        let peerIdsToInsert = folder.peerIds
            .lazy
            .filter { peerId in
                !managedFolder.peerIds.contains { $0.id == peerId.id && $0.namespace == peerId.namespace }
            }
            .map { ManagedPeerId(context: self.context, plainEntity: $0) }
            .collect()

        managedFolder.name = folder.name
        managedFolder.pinningIndex = folder.pinningIndex.map { Int16($0) } ?? -1
        managedFolder.removeFromStoredPeerIds(peerIdsToDelete as NSSet)
        managedFolder.addToStoredPeerIds(peerIdsToInsert as NSSet)

        // TODO: Investigate. This is supposed to be done in `removeFromStoredPeerIds(_:)` method.
        peerIdsToDelete.forEach(managedFolder.managedObjectContext!.delete)
    }

    private func delete(managedFolder: ManagedFolder) {
        let id = managedFolder.id

        managedFolder.removeFromStoredPeerIds(managedFolder.storedPeerIds ?? NSSet())
        context.delete(managedFolder)

        cachedFolders.removeValue(forKey: id)
    }

}

// MARK: - Types

extension FolderStorage {

    enum Result<T> {
        case success(T)
        case failure(Swift.Error)
    }

    enum Error: Swift.Error {
        case failedToSave
        case failedToRetrieve
    }

}
