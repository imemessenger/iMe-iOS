//
//  Sequence+Iterators.swift
//  AiGramLib
//
//  Created by Valeriy Mikholapov on 07/07/2019.
//  Copyright © 2019 Ol Corporation. All rights reserved.
//

import Foundation

public extension Sequence {
    func dict<K: Hashable, V>(_ combine: (V, V) -> V = { $1 }) -> [K: V] where Self.Element == (K, V) {
        return .init(self, uniquingKeysWith: combine)
    }

    func collect<K: Hashable, V>() -> [K: V] where Self.Element == (K, V) {
        return dict { val, _ in val }
    }
    
    func collect() -> [Element] {
        return map { $0 }
    }
}

public extension Sequence where Element: Hashable {
    func collect() -> Set<Element> {
        return .init(self)
    }
}

public extension Sequence where Element: Collection {
    func flatten<T>() -> [T] where Element.Element == T {
        return flatMap { $0 }
    }
}

public func +<Key, Value> (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
    var result = lhs
    rhs.forEach { result[$0] = $1 }
    return result
}

