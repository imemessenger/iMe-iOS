//
//  Unwrappers.swift
//  AiGramLib
//
//  Created by Oleksandr Shynkarenko on 9/4/19.
//  Copyright © 2019 Ol Corporation. All rights reserved.
//

import Foundation

func someRegionCode(_ s: String?) -> String {
    return s ?? Locale.current.regionCode?.lowercased() ?? "ru"
}   

func someBotLanguage(_ s: String?) -> String {
    return s ?? "ru"
}
