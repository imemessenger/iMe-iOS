//
//  CATransaction+DisabledActions.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 06/07/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit

extension CATransaction {

    static func withDisabledActions(_ f: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        f()

        CATransaction.commit()
    }

}
