//
//  UIEdgeInsets+ConvenienceMethods.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 26/06/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit

extension UIEdgeInsets {
    static func insets(
        from original: UIEdgeInsets = .zero,
        top: CGFloat = 0.0,
        right: CGFloat = 0.0,
        bottom: CGFloat = 0.0,
        left: CGFloat = 0.0
    ) -> UIEdgeInsets {
        return .init(
            top: original.top + top,
            left: original.left + left,
            bottom: original.bottom + bottom,
            right: original.right + right
        )
    }

    static func insets(
        from original: UIEdgeInsets = .zero,
        all: CGFloat = 0.0
    ) -> UIEdgeInsets {
        return .init(
            top: original.top + all,
            left: original.left + all,
            bottom: original.bottom + all,
            right: original.right + all
        )
    }

    static func insets(
        from original: UIEdgeInsets = .zero,
        vertical: CGFloat = 0.0,
        horizontal: CGFloat = 0.0
    ) -> UIEdgeInsets {
        return .init(
            top: original.top + vertical,
            left: original.left + horizontal,
            bottom: original.bottom + vertical,
            right: original.right + horizontal
        )
    }
}
