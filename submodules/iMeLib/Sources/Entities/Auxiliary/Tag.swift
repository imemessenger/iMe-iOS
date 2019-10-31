//
//  Tag.swift
//  AiGramLib
//
//  Created by Valeriy Mikholapov on 01/07/2019.
//  Copyright © 2019 Ol Corporation. All rights reserved.
//

protocol Taggable {
    var tags: [Tag<Self>] { get }
}

public struct Tag<Entity>: Equatable, Hashable {
    public typealias Id = Tagged<Tag<Entity>, String>

    public let id: Id
    public let text: String
}
