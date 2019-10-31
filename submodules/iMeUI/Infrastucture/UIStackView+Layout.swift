//
//  UIStackView+Layout.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 25/06/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit

extension UIStackView {
    @discardableResult
    func sva(_ subviews: UIView...) -> UIStackView {
        return sva(subviews)
    }

    @discardableResult
    func sva(_ subviews: [UIView]) -> UIStackView {
        subviews.forEach {
            addArrangedSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        return self
    }
}
