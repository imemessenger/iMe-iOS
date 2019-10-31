//
//  ChatSelectionControllerNode.swift
//  iMeUI
//
//  Created by Valeriy Mikholapov on 17/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Display
import AsyncDisplayKit
import UIKit
import Postbox
import TelegramCore
import SwiftSignalKit
import iMeLib
import AccountContext
import MergeLists
import ContactListUI
import TelegramPresentationData
import QuartzCore


struct EditableTokenListToken {
    let id: AnyHashable
    let title: String
}

private struct SearchResultEntry: MergeLists.Identifiable {
    let index: Int
    let peer: Peer

    var stableId: Int64 {
        return self.peer.id.toInt64()
    }

    static func ==(lhs: SearchResultEntry, rhs: SearchResultEntry) -> Bool {
        return lhs.index == rhs.index && lhs.peer.isEqual(rhs.peer)
    }

    static func <(lhs: SearchResultEntry, rhs: SearchResultEntry) -> Bool {
        return lhs.index < rhs.index
    }
}

final class ChatSelectionControllerNode: ASDisplayNode {
    let contactListNode: ChatListSelectionNode
    var searchResultsNode: ContactListNode?

    private let context: AccountContext

    private var containerLayout: (ContainerViewLayout, CGFloat, CGFloat)?

    var requestDeactivateSearch: (() -> Void)?
    var requestOpenPeerFromSearch: ((ChatListSelectionPeerId) -> Void)?
    var openPeer: ((ChatListSelectionPeer) -> Void)?
    var removeSelectedPeer: ((ChatListSelectionPeerId) -> Void)?

    var editableTokens: [EditableTokenListToken] = []

    private let searchResultsReadyDisposable = MetaDisposable()
    var dismiss: (() -> Void)?

    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?

    init(context: AccountContext, options: [ChatListSelectionAdditionalOption], filters: [ChatListSelectionFilter]) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }

        self.contactListNode = ChatListSelectionNode(context: context, presentation: .natural(displaySearch: false, options: options), filters: filters, selectionState: ChatListSelectionNodeGroupSelectionState())

        super.init()

        self.setViewBlock({
            return UITracingLayerView()
        })

        self.backgroundColor = self.presentationData.theme.chatList.backgroundColor

        self.addSubnode(self.contactListNode)

        self.contactListNode.openPeer = { [weak self] peer in
            self?.openPeer?(peer)
        }

        let searchText = ValuePromise<String>()

        self.presentationDataDisposable = (context.sharedContext.presentationData
            |> deliverOnMainQueue).start(next: { [weak self] presentationData in
                if let strongSelf = self {
                    let previousTheme = strongSelf.presentationData.theme
                    let previousStrings = strongSelf.presentationData.strings

                    strongSelf.presentationData = presentationData

                    if previousTheme !== presentationData.theme || previousStrings !== presentationData.strings {
                        strongSelf.updateThemeAndStrings()
                    }
                }
            })
    }

    deinit {
        self.searchResultsReadyDisposable.dispose()
    }

    private func updateThemeAndStrings() {
        self.backgroundColor = self.presentationData.theme.chatList.backgroundColor
    }

    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, actualNavigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        self.containerLayout = (layout, navigationBarHeight, actualNavigationBarHeight)

        var insets = layout.insets(options: [.input])
        insets.top += navigationBarHeight

        var headerInsets = layout.insets(options: [.input])
        headerInsets.top += actualNavigationBarHeight
        
//        ContainerViewLayout(size: layout.size, metrics: layout.metrics, deviceMetrics: layout.deviceMetrics, intrinsicInsets: insets, safeInsets: layout.safeInsets, statusBarHeight: layout.statusBarHeight, inputHeight: layout.inputHeight, inputHeightIsInteractivellyChanging: layout.inputHeightIsInteractivellyChanging, inVoiceOver: layout.inVoiceOver)
        
        self.contactListNode.containerLayoutUpdated(ContainerViewLayout(size: layout.size, metrics: layout.metrics, deviceMetrics: layout.deviceMetrics, intrinsicInsets: insets, safeInsets: layout.safeInsets, statusBarHeight: layout.statusBarHeight, inputHeight: layout.inputHeight, inputHeightIsInteractivellyChanging: layout.inputHeightIsInteractivellyChanging, inVoiceOver: layout.inVoiceOver), transition: transition)
        self.contactListNode.frame = CGRect(origin: CGPoint(), size: layout.size)
        
        if let searchResultsNode = self.searchResultsNode {
            searchResultsNode.containerLayoutUpdated(ContainerViewLayout(size: layout.size, metrics: layout.metrics, deviceMetrics: layout.deviceMetrics, intrinsicInsets: insets, safeInsets: layout.safeInsets, statusBarHeight: layout.statusBarHeight, inputHeight: layout.inputHeight, inputHeightIsInteractivellyChanging: layout.inputHeightIsInteractivellyChanging, inVoiceOver: layout.inVoiceOver), headerInsets: headerInsets, transition: transition)
            searchResultsNode.frame = CGRect(origin: CGPoint(), size: layout.size)
        }
    }

    func animateIn() {
        self.layer.animatePosition(from: CGPoint(x: self.layer.position.x, y: self.layer.position.y + self.layer.bounds.size.height), to: self.layer.position, duration: 0.5, timingFunction: kCAMediaTimingFunctionSpring)
    }

    func animateOut(completion: (() -> Void)?) {
        let position = CGPoint(x: self.layer.position.x, y: self.layer.position.y + self.layer.bounds.size.height)
        
        self.layer.animatePosition(from: self.layer.position, to: position, duration: 0.2, timingFunction: CAMediaTimingFunctionName.easeInEaseOut.rawValue, removeOnCompletion: false, completion: { [weak self] _ in
            if let strongSelf = self {
                strongSelf.dismiss?()
                completion?()
            }
        })
    }
}
