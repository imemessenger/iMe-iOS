//
//  Folder.swift
//  Postbox
//
//  Created by Valeriy Mikholapov on 16/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

public let folderPeerIdNamespace: Int32 = 100

public final class Folder {
    public typealias Id = Int32

    public let folderId: Id
    public var name: String
    public var peerIds: Set<PeerId>
    public var lastMessage: Message?
    public var unreadCount: UInt?
    public var pinningIndex: UInt16?

    init(
        folderId: Id,
        name: String,
        peerIds: [PeerId],
        pinningIndex: UInt16?
    ) {
        self.folderId = folderId
        self.name = name
        self.peerIds = Set(peerIds)
        self.pinningIndex = pinningIndex
    }
}

extension Folder: Peer {

    public var id: PeerId {
        return .init(namespace: folderPeerIdNamespace, id: -folderId)
    }

    public var indexName: PeerIndexNameRepresentation {
        return .title(title: name, addressName: nil)
    }

    public var associatedPeerId: PeerId? {
        return nil
    }

    public var notificationSettingsPeerId: PeerId? {
        return nil
    }

    public func isEqual(_ other: Peer) -> Bool {
        guard let other = other as? Folder, folderId == other.folderId else {
            return false
        }
        return true
    }

    public convenience init(decoder: PostboxDecoder) {
        fatalError("Not implemented")
    }

    public func encode(_ encoder: PostboxEncoder) {
        fatalError("Not implemented")
    }    

}

public extension PeerId {
    var isFolderId: Bool {
        return namespace == folderPeerIdNamespace
    }
}
