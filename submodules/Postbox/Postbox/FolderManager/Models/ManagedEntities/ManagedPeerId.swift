//
//  ManagedPeerId.swift
//  Postbox
//
//  Created by Valeriy Mikholapov on 21/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import CoreData

extension ManagedPeerId {

    convenience init(context: NSManagedObjectContext, plainEntity: PeerId) {
        self.init(context: context)

        namespace = plainEntity.namespace
        id = plainEntity.id
    }

    func toPlainEntity() -> PeerId {
        return PeerId(namespace: namespace, id: id)
    }

}

extension Sequence where Element == ManagedPeerId {

    func toPlainEntities() -> [PeerId] {
        return map { $0.toPlainEntity() }
    }

}
