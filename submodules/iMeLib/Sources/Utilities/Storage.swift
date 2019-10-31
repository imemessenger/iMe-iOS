//
//  Storage.swift
//  AiGramLib
//
//  Created by Valeriy Mikholapov on 07/07/2019.
//  Copyright © 2019 Ol Corporation. All rights reserved.
//

import Foundation

protocol Storage {
    func set<T>(value: T, forKey: String)
    func getValue<T>(forKey: String) -> T?
}

extension UserDefaults: Storage {
    func set<T>(value: T, forKey key: String) {
        set(value, forKey: key)
    }

    func getValue<T>(forKey key: String) -> T? {
        return object(forKey: key) as? T
    }
}
