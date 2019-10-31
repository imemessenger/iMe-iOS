//
//  Localisation.swift
//  AiGramLib
//
//  Created by Valeriy Mikholapov on 01/07/2019.
//  Copyright © 2019 Ol Corporation. All rights reserved.
//

struct Localisation<T, Translation> {
    let locales: [String: Translation]
    let defaultLocalisation: Translation
}
