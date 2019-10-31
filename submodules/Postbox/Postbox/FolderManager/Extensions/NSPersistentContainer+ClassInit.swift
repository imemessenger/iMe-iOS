//
//  NSPersistentContainer+ClassInit.swift
//  Postbox
//
//  Created by Valeriy Mikholapov on 25/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import CoreData

extension NSPersistentContainer {

    convenience init?<T: NSManagedObject>(type: T.Type) {
        guard let model = NSManagedObjectModel(type: type) else {
            return nil
        }

        self.init(name: String(describing: type), managedObjectModel: model)
    }

}
