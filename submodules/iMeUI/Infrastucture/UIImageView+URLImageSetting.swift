//
//  UIImageView+URLImageSetting.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 28/06/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit
import Display
import SDWebImage
import TelegramPresentationData

private let botDayImage = UIImage(bundleImageName: "Bot Store/BotPlaceholderImage")!
private let botNightImage = UIImage(bundleImageName: "Bot Store/BotPlaceholderNightImage")!
private let botBlueNightImage = UIImage(bundleImageName: "Bot Store/BotPlaceholderNightBlueImage")!
private let botIconDayImage = UIImage(bundleImageName: "Bot Store/BotPlaceholderIcon")!
private let botIconNightImage = UIImage(bundleImageName: "Bot Store/BotPlaceholderNightIcon")!
private let botIconBlueNightImage = UIImage(bundleImageName: "Bot Store/BotPlaceholderNightBlueIcon")!

private let imageManager = SDWebImageManager.shared

public enum Placeholder {
    case botDay, botNight, botBlueNight
    case botIconDay, botIconNight, botIconBlueNight

    public init(theme: PresentationTheme) {
        if case let .builtin(name) = theme.name {
            switch name {
                case .day, .dayClassic:
                    self = .botDay
                case .night:
                    self = .botNight
                case .nightAccent:
                    self = .botBlueNight
            }
        } else {
            self = .botDay
        }
    }

    fileprivate var image: UIImage {
        switch self {
            case .botDay:
                return botDayImage
            case .botNight:
                return botNightImage
            case .botBlueNight:
                return botBlueNightImage
            case .botIconDay:
                return botIconDayImage
            case .botIconNight:
                return botIconNightImage
            case .botIconBlueNight:
                return botIconBlueNightImage
        }
    }
}

private var placeholders: [UIImageView: Placeholder] = [:]

public extension UIImageView {

    func set(placeholder: Placeholder) {
        placeholders[self] = placeholder
    }

    func setImage(fromUrl url: URL?) {
        let placeholder = placeholders[self]?.image
        self.sd_setImage(with: url, placeholderImage: placeholder, options: .retryFailed, context: nil)
    }

}

public extension ASImageNode {

    func setImage(fromUrl url: URL?, with placeholder: Placeholder?) {
        image = placeholder?.image
        imageManager.loadImage(
            with: url,
            options: .retryFailed,
            progress: nil
        ) { [weak self] image, _, error, _, _, _ in
            if let error = error {
                print("Error setting an image from url: \(error)")
            }
            self?.image = image
        }
    }

}
