//
//  Dependencies.swift
//  AiGramLib
//
//  Created by Valeriy Mikholapov on 01/07/2019.
//  Copyright © 2019 Ol Corporation. All rights reserved.
//

import Foundation
import Firebase
import FirebaseCore

struct Dependencies {
    private init() { }
//    static let firestore: FirestoreGateway = .init(firestore: .firestore())
    
    static let appStoreReceiptBundle: Bundle = Bundle.main
    static let baseUrl: URL = URL(string: "https://us-central1-api-7231730271161646241-853730.cloudfunctions.net").unsafelyUnwrapped
    static let storage: Storage = UserDefaults.standard
    static let botModelsRelativePath: String = "chatbots"
//    static let integratedBotModelsUrl: URL = Bundle(for: BotProcessor.self).url(forResource: "chatbots", withExtension: nil)!
}
