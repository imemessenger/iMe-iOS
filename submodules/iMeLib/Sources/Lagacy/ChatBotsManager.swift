//
//  ChatBotsManager.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 25/12/2018.
//  Copyright © 2018 Telegram. All rights reserved.
//

import Foundation
import UIKit
import FirebaseCore
import SwiftSignalKit

public enum Result<T> {
    case success(T)
    case fail(Error)
}

public final class ChatBotsManager {
    public static let shared: ChatBotsManager = .init()
    private var queue: OperationQueue
    private var baseLanguageCode: String = ""

    // MARK: - State
    
    public func updateLanguageCodeAndLoadBots(_ code: String) {
        queue.addOperation { [weak self] in
            guard let self = self else {
                return
            }
            
            if self.baseLanguageCode != code {
                self.baseLanguageCode = code == "ru" || code == "en" ? code : "ru"
            }
        }
    }

    public var shareText: String {
        if baseLanguageCode == "ru" {
            return
                """
                Привет, вместо Telegram я использую iMe – мессенджер с Искусственным интеллектом! Скачай его здесь https://imem.app/dl и общайся с пользователями Telegram по-новому, используя нейроботов-помощников в чатах.
                """
        } else {
            return
                """
                Hi, instead of Telegram I use iMe - an messenger with Artificial Intelligence! Download it here https://imem.app/dl and communicate with Telegram users in a new way using neurobot assistants in chats.
                """
        }
    }

    private init() {
        FirebaseApp.configure()

        queue = OperationQueue()
        queue.qualityOfService = .userInteractive
    }
}
