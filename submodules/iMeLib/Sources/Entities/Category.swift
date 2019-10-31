//
//  Category.swift
//  AiGramLib
//
//  Created by Valeriy Mikholapov on 01/07/2019.
//  Copyright © 2019 Ol Corporation. All rights reserved.
//

public struct Category<Entity>: Equatable, Hashable {
    public typealias Id = Tagged<Category<Entity>, String>

    public let id: Id
    public let title: String
    public let priority: Int?
    public let tagIds: Set<Tag<Entity>.Id>

    init(
        id: Id,
        title: String,
        priority: Int?,
        tagIds: Set<Tag<Entity>.Id>
    ) {
        self.id = id
        self.title = title
        self.priority = priority
        self.tagIds = tagIds
    }

    init<Other>(from other: Category<Other>) {
        self.id = .init(rawValue: other.id.rawValue)
        self.title = other.title
        self.priority = other.priority
        self.tagIds = other
            .tagIds
            .map { .init(rawValue: $0.rawValue) }
            .collect()
    }
}

extension Category where Entity: Taggable {
    func includesAny(of entities: [Entity]) -> Bool {
        return entities.contains { includes(entity: $0) }
    }

    func includes(entity: Entity) -> Bool {
        return entity.tags.contains {
            tagIds.contains($0.id)
        }
    }
}
