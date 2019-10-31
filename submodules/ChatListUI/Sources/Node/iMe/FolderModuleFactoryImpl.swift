//
//  FolderModuleFactoryImpl.swift
//  ChatListUI
//
//  Created by Oleksandr Shynkarenko on 10/18/19.
//  Copyright © 2019 Telegram Messenger LLP. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import Postbox
import Display
import TelegramPresentationData
import TelegramUIPreferences
import iMeUI
import AccountContext

public class FolderModuleFactoryImpl: FolderModuleFactory {
    public static var `default`: FolderModuleFactoryImpl = .init()
    
    public func makeChatListEmptyNode(theme: PresentationTheme, strings: PresentationStrings) -> ChatListEmptyNodeInterface {
        return ChatListEmptyNode(theme: theme, strings: strings)
    }
    
    public func makeChatListNode(
        context: AccountContext,
        groupId: PeerGroupId,
        controlsHistoryPreload: Bool,
        mode: ImeChatListNodeMode,
        theme: PresentationTheme,
        strings: PresentationStrings,
        dateTimeFormat: PresentationDateTimeFormat,
        nameSortOrder: PresentationPersonNameOrder,
        nameDisplayOrder: PresentationPersonNameOrder,
        setupChatListModeHandler: SetupChatListModeCallback?,
        disableAnimations: Bool
    ) -> ChatListNodeInterface {
        
        var chatListMode: ChatListNodeMode
        
        switch mode {
        case .chatList:
            chatListMode = .chatList
        case let .peers(filter: filter, showAsChatList: showAsChatList):
            chatListMode = .peers(filter: filter, showAsChatList: showAsChatList)
        }
        
        return ChatListNode(
            context: context,
            groupId: groupId,
            controlsHistoryPreload: controlsHistoryPreload,
            mode: chatListMode,
            theme: theme,
            strings: strings,
            dateTimeFormat: dateTimeFormat,
            nameSortOrder: nameSortOrder,
            nameDisplayOrder: nameDisplayOrder,
            setupChatListModeHandler: setupChatListModeHandler,
            disableAnimations: disableAnimations
        )
    }
}
