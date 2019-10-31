//
//  ManagedFolder.swift
//  Postbox
//
//  Created by Valeriy Mikholapov on 16/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import CoreData

extension ManagedFolder {

    var peerIds: Set<ManagedPeerId> {
        get {
            return storedPeerIds.assertNonNil()?
                .lazy
                .map { $0 as? ManagedPeerId }
                .compactMap { $0.assertNonNil() }
                .collect() ?? []
        }

        set { storedPeerIds = newValue as NSSet }
    }

    convenience init(context: NSManagedObjectContext, plainEntity: Folder) {
        self.init(context: context)

        id = plainEntity.folderId
        name = plainEntity.name
        peerIds = plainEntity.peerIds
            .map { ManagedPeerId(context: context, plainEntity: $0) }
            .collect()
    }

    func toPlainEntity() -> Folder {
        return Folder(
            folderId: id,
            name: name ?? "",
            peerIds: peerIds.toPlainEntities(),
            pinningIndex: pinningIndex < 0 ? nil : UInt16(pinningIndex)
        )
    }

}


