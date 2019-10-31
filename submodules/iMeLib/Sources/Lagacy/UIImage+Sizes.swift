//
//  UIImage+Sizes.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 17/01/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit

extension UIImage {
    convenience init?(in folder: URL, name: String, ext: String) {
        var nameWithScale = name
        let name = "\(name).\(ext)"
        let scale = UIScreen.main.scale
        if scale != 1 {
            nameWithScale = "\(nameWithScale)@\(Int(scale))x"
        }
        nameWithScale = "\(nameWithScale).\(ext)"
        var url = folder.appendingPathComponent(nameWithScale)
        if !((try? url.checkResourceIsReachable()) ?? false) {
            url = folder.appendingPathComponent(name)
        }
        if !((try? url.checkResourceIsReachable()) ?? false) {
            return nil
        }
        if let data = try? Data(contentsOf: url) {
            self.init(data: data)
            return
        }
        return nil
    }
}
