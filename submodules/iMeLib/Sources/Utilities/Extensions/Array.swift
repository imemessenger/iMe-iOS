//
//  Array.swift
//  iMeLib
//
//  Created by Oleksandr Shynkarenko on 9/23/19.
//  Copyright © 2019 Valeriy Mikholapov. All rights reserved.
//

import Foundation

extension Array {
    public static func + (_ arr: [Element], _ el: Element) -> [Element] {
        var newArr = arr
        newArr.append(el)
        return newArr
    }
    
    public static func += (_ arr: inout [Element], _ el: Element) {
        arr.append(el)
    }
}
