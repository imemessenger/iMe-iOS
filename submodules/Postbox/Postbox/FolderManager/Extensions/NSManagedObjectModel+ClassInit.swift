//
//  NSManagedObjectModel+ClassInit.swift
//  Postbox
//
//  Created by Valeriy Mikholapov on 25/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import CoreData

extension NSManagedObjectModel {

    convenience init?<T: NSManagedObject>(type: T.Type) {
        guard let modelUrl = Bundle(for: type).url(forResource: String(describing: type), withExtension: "momd") else {
            return nil
        }

        self.init(contentsOf: modelUrl)
    }

}
