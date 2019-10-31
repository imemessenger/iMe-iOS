//
//  PresentationResourcesIME.swift
//  iMeUI
//
//  Created by Oleksandr Shynkarenko on 10/3/19.
//  Copyright © 2019 Valeriy Mikholapov. All rights reserved.
//

import Foundation
import TelegramPresentationData
import Display
import iMePresentationStorage

struct PresentationResourcesIME {
    static func statStarIcon(_ theme: PresentationTheme) -> UIImage? {
        let color = theme.iMe.titleTextColour
        
        return IMeImageAsset.with(.filledStarIcon(color))
    }

    static func filledStarIcon(_ theme: PresentationTheme) -> UIImage? {
        let color = theme.iMe.accentColour
        
        return IMeImageAsset.with(.filledStarIcon(color))
    }

    static func shallowStarIcon() -> UIImage? {
        return IMeImageAsset.with(.shallowStarIcon)
    }

    static func menuIcon(_ theme: PresentationTheme) -> UIImage? {
        let color = NavigationBarTheme(rootControllerTheme: theme).buttonColor
        
        return IMeImageAsset.with(.menuIcon(color))
    }

    static func checkMark() -> UIImage? {
        return IMeImageAsset.with(.checkMark)
    }
}
