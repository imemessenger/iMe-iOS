//
//  IMeImageAsset.swift
//  iMePresentationStorage
//
//  Created by Oleksandr Shynkarenko on 10/3/19.
//  Copyright © 2019 Oleksandr Shynkarenko. All rights reserved.
//

import Display

public enum IMeImageAssetKey {
    // MARK: - Bot store & Channel Collection
    case statStartIcon(UIColor)
    case filledStarIcon(UIColor)
    case shallowStarIcon
    case menuIcon(UIColor)
    case checkMark
    // MARK: - Filtering TabBar
    case allChats
    case unreadChats
    case personalChats
    case groupChats
    case channels
    case bots
    case customGrouping
    // MARK: - Chat list
    case addIcon(UIColor)
    case channelCollectionIcon(UIColor)
    case composeIcon(UIColor)
    case readAllMessageIcon(UIColor)
    // MARK: - Folder
    case addMemberIcon(UIColor)
    case trashIcon(UIColor)
    // MARK: - Bot
    case suggestionsIcon(UIColor)
    case recent
    
    public var color: UIColor? {
        switch self {
        case
            .statStartIcon(let color),
            .filledStarIcon(let color),
            .menuIcon(let color),
            .addIcon(let color),
            .channelCollectionIcon(let color),
            .composeIcon(let color),
            .readAllMessageIcon(let color),
            .addMemberIcon(let color),
            .trashIcon(let color),
            .suggestionsIcon(let color):
                return color
        default:
            return nil
        }
    }
}

public struct IMeImageAsset {
    static public func with(_ key: IMeImageAssetKey) -> UIImage? {
        let image = UIImage(bundleImageName: path(for: key))
        
        if let color = key.color {
            return generateTintedImage(image: image, color: color)
        }
        
        return image
    }
    
    static private func path(for key: IMeImageAssetKey) -> String {
        switch key {
        case .statStartIcon, .filledStarIcon:
            return "Bot Store/FilledStar"
        case .shallowStarIcon:
            return "Bot Store/ShallowStar"
        case .menuIcon:
            return "Instant View/MoreIcon"
        case .checkMark:
            return "Chat/Empty Chat/ListCheckIcon"
        case .allChats:
            return "Chat Grouping Tabs/AllChats"
        case .unreadChats:
            return "Chat Grouping Tabs/UnreadChats"
        case .personalChats:
            return "Chat Grouping Tabs/PersonalChats"
        case .groupChats:
            return "Chat Grouping Tabs/GroupChats"
        case .channels:
            return "Chat Grouping Tabs/Channels"
        case .bots:
            return "Chat Grouping Tabs/Bots"
        case .customGrouping:
            return "Chat Grouping Tabs/CustomGrouping"
        case .addIcon:
            return "Chat List/AddIcon"
        case .channelCollectionIcon:
            return "Chat List/ChannelCollectionIcon"
        case .composeIcon:
            return "Chat List/ComposeIcon"
        case .readAllMessageIcon:
            return "Chat List/ReadAllMessagesIcon"
        case .addMemberIcon:
            return "Folder Title Panel/AddMemberIcon"
        case .trashIcon:
            return "Folder Title Panel/TrashIcon"
        case .suggestionsIcon:
            return "Chat/Input/Text/AccessoryIconSuggestions"
        case .recent:
            return "Chat/Input/Media/RecentTabIcon"
        }
    }
}
