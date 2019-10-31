//
//  CategorisedCollection.swift
//  AiGramLib
//
//  Created by Valeriy Mikholapov on 26/07/2019.
//  Copyright © 2019 Ol Corporation. All rights reserved.
//

public struct CategorisedCollection<Entity> {
    public let category: Category<Entity>
    public let collection: [Entity]
}

extension CategorisedCollection: Equatable where Entity: Equatable { }
