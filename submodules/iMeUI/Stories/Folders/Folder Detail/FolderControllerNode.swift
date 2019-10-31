//
//  FolderControllerNode.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 30/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import Display
import Postbox
import TelegramCore
import AccountContext
import TelegramPresentationData
import ActivityIndicator
import SearchUI
import TelegramUIPreferences
import SwiftSignalKit

// MARK: - Boiler plate START

public enum ImeChatListNodeEmptyState: Equatable {
    case notEmpty(containsChats: Bool)
    case empty(isLoading: Bool)
}

public enum ImeChatListNodeMode {
    case chatList
    case peers(filter: ChatListNodePeersFilter, showAsChatList: Bool)
}

public protocol ChatListEmptyNodeInterface: ASDisplayNode { // ChatListEmptyNode
    func updateThemeAndStrings(theme: PresentationTheme, strings: PresentationStrings)
    func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition)
}

public protocol ChatListNodeInterface: ListView {
    var peerSelected: ((PeerId, Bool, Bool) -> Void)? { get set }
    var groupSelected: ((PeerGroupId) -> Void)? { get set }
    var activateSearch: (() -> Void)? { get set }
    var deletePeerChat: ((PeerId) -> Void)? { get set }
    var updatePeerGrouping: ((PeerId, Bool) -> Void)? { get set }
    var presentAlert: ((String) -> Void)? { get set }
    
    var ready: Signal<Bool, NoError> { get }
    var iMEisEmptyUpdated: ((ImeChatListNodeEmptyState) -> Void)? { get set }
    
    func updateSelectedChatLocation(_ chatLocation: ChatLocation?, progress: CGFloat, transition: ContainedViewLayoutTransition)
    func updateLayout(transition: ContainedViewLayoutTransition, updateSizeAndInsets: ListViewUpdateSizeAndInsets)
    
    func updateThemeAndStrings(
        theme: PresentationTheme,
        strings: PresentationStrings,
        dateTimeFormat: PresentationDateTimeFormat,
        nameSortOrder: PresentationPersonNameOrder,
        nameDisplayOrder: PresentationPersonNameOrder,
        disableAnimations: Bool
    )
    
    func scrollToTop()
}

public protocol FolderModuleFactory {
    func makeChatListEmptyNode(theme: PresentationTheme, strings: PresentationStrings) -> ChatListEmptyNodeInterface
    
    func makeChatListNode(
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
    ) -> ChatListNodeInterface
}

// MARK: - Boilder plate END


private final class FolderControllerNodeView: UITracingLayerView, PreviewingHostView {
    var previewingDelegate: PreviewingHostViewDelegate? {
        return PreviewingHostViewDelegate(controllerForLocation: { [weak self] sourceView, point in
            return self?.controller?.previewingController(from: sourceView, for: point)
            }, commitController: { [weak self] controller in
                self?.controller?.previewingCommit(controller)
        })
    }

    weak var controller: FolderController?
}

class FolderControllerNode: ASDisplayNode {
    private var factory: FolderModuleFactory
    
    private let context: AccountContext
    private let groupId: PeerGroupId?
    private var presentationData: PresentationData

    var isTitlePanelShown: Bool = false
    private let titleAccessoryPanelContainer: ChatControllerTitlePanelNodeContainerInterface
    private let titlePanelNode: FolderTitlePanelNode

    private var chatListEmptyNode: ChatListEmptyNodeInterface?
    private var chatListEmptyIndicator: ActivityIndicator?
    let chatListNode: ChatListNodeInterface
    var navigationBar: NavigationBar?
    weak var controller: FolderController?

    private(set) var searchDisplayController: SearchDisplayController?

    private var containerLayout: (ContainerViewLayout, CGFloat, CGFloat)?

    var requestDeactivateSearch: (() -> Void)?
    var requestOpenPeerFromSearch: ((Peer, Bool) -> Void)?
    var requestOpenRecentPeerOptions: ((Peer) -> Void)?
    var requestOpenMessageFromSearch: ((Peer, MessageId) -> Void)?
    var requestAddContact: ((String) -> Void)?
    var dismissSelf: (() -> Void)?

    init(context: AccountContext, groupId: PeerGroupId, controlsHistoryPreload: Bool, presentationData: PresentationData, controller: FolderController, factory: FolderModuleFactory, setupChatListModeHandler: SetupChatListModeCallback? = nil, titlePanelInteraction: FolderInfoTitlePanelInteration? = nil) {
        self.factory = factory
        self.context = context
        self.groupId = groupId
           
        self.chatListNode = self.factory.makeChatListNode(
            context: context,
            groupId: groupId,
            controlsHistoryPreload: controlsHistoryPreload,
            mode: .chatList,
            theme: presentationData.theme,
            strings: presentationData.strings,
            dateTimeFormat: presentationData.dateTimeFormat,
            nameSortOrder: presentationData.nameSortOrder,
            nameDisplayOrder: presentationData.nameDisplayOrder,
            setupChatListModeHandler: setupChatListModeHandler,
            disableAnimations: presentationData.disableAnimations
        )

        self.presentationData = presentationData

        self.controller = controller
        
        titleAccessoryPanelContainer = self.context.sharedContext.makeChatControllerTitlePanelNodeContainerInterface()
        titleAccessoryPanelContainer.clipsToBounds = true

        titlePanelNode = FolderTitlePanelNode()
        titlePanelNode.interfaceInteraction = titlePanelInteraction

        super.init()

        self.setViewBlock({
            return FolderControllerNodeView()
        })

        self.backgroundColor = presentationData.theme.chatList.backgroundColor

        self.addSubnode(self.chatListNode)
        
        self.chatListNode.iMEisEmptyUpdated = { [weak self] isEmptyState in
            guard let strongSelf = self else {
                return
            }
            switch isEmptyState {
            case .empty(false):
                if case .group? = strongSelf.groupId {
                    strongSelf.dismissSelf?()
                } else if strongSelf.chatListEmptyNode == nil {
                    let chatListEmptyNode = strongSelf.factory.makeChatListEmptyNode(
                        theme: strongSelf.presentationData.theme,
                        strings: strongSelf.presentationData.strings
                    )
                    
                    strongSelf.chatListEmptyNode = chatListEmptyNode
                    strongSelf.insertSubnode(chatListEmptyNode, belowSubnode: strongSelf.chatListNode)
                    if let (layout, navigationHeight, visualNavigationHeight) = strongSelf.containerLayout {
                        strongSelf.containerLayoutUpdated(layout, navigationBarHeight: navigationHeight, visualNavigationHeight: visualNavigationHeight, transition: .immediate)
                    }
                }
            case .notEmpty(false):
                if case .group? = strongSelf.groupId {
                    strongSelf.dismissSelf?()
                }
            default:
                if let chatListEmptyNode = strongSelf.chatListEmptyNode {
                    strongSelf.chatListEmptyNode = nil
                    chatListEmptyNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak chatListEmptyNode] _ in
                        chatListEmptyNode?.removeFromSupernode()
                    })
                }
            }
            switch isEmptyState {
                case .empty(true):
                    if strongSelf.chatListEmptyIndicator == nil {
                        let chatListEmptyIndicator = ActivityIndicator(type: .custom(strongSelf.presentationData.theme.list.itemAccentColor, 22.0, 1.0, false))
                        strongSelf.chatListEmptyIndicator = chatListEmptyIndicator
                        strongSelf.insertSubnode(chatListEmptyIndicator, belowSubnode: strongSelf.chatListNode)
                        if let (layout, navigationHeight, visualNavigationHeight) = strongSelf.containerLayout {
                            strongSelf.containerLayoutUpdated(layout, navigationBarHeight: navigationHeight, visualNavigationHeight: visualNavigationHeight, transition: .immediate)
                        }
                    }
                default:
                    if let chatListEmptyIndicator = strongSelf.chatListEmptyIndicator {
                        strongSelf.chatListEmptyIndicator = nil
                        chatListEmptyIndicator.removeFromSupernode()
                    }
            }
        }



//            { [weak self] isEmptyState in
//            guard let strongSelf = self else {
//                return
//            }
//            if isEmpty {
//                if strongSelf.chatListEmptyNode == nil {
//                    let chatListEmptyNode = ChatListEmptyNode(theme: strongSelf.presentationData.theme, strings: strongSelf.themeAndStrings.1)
//                    strongSelf.chatListEmptyNode = chatListEmptyNode
//                    strongSelf.insertSubnode(chatListEmptyNode, belowSubnode: strongSelf.chatListNode)
//                    if let (layout, navigationHeight) = strongSelf.containerLayout {
//                        strongSelf.containerLayoutUpdated(layout, navigationBarHeight: navigationHeight, transition: .immediate)
//                    }
//                }
//            } else if let chatListEmptyNode = strongSelf.chatListEmptyNode {
//                strongSelf.chatListEmptyNode = nil
//                chatListEmptyNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak chatListEmptyNode] _ in
//                    chatListEmptyNode?.removeFromSupernode()
//                })
//            }
//        }

        addSubnode(titleAccessoryPanelContainer)
        titleAccessoryPanelContainer.addSubnode(titlePanelNode)
    }

    override func didLoad() {
        super.didLoad()

        (self.view as? FolderControllerNodeView)?.controller = self.controller
    }

    func updatePresentationData(_ presentationData: PresentationData) {
        self.presentationData = presentationData

        self.backgroundColor = self.presentationData.theme.chatList.backgroundColor

        self.chatListNode.updateThemeAndStrings(theme: self.presentationData.theme, strings: self.presentationData.strings, dateTimeFormat: self.presentationData.dateTimeFormat, nameSortOrder: self.presentationData.nameSortOrder, nameDisplayOrder: self.presentationData.nameDisplayOrder, disableAnimations: self.presentationData.disableAnimations)
        self.searchDisplayController?.updatePresentationData(presentationData)
        self.chatListEmptyNode?.updateThemeAndStrings(theme: self.presentationData.theme, strings: self.presentationData.strings)
    }

//    func updateThemeAndStrings(theme: PresentationTheme, strings: PresentationStrings, dateTimeFormat: PresentationDateTimeFormat, nameSortOrder: PresentationPersonNameOrder, nameDisplayOrder: PresentationPersonNameOrder, disableAnimations: Bool) {
//        self.themeAndStrings = (theme, strings, dateTimeFormat)
//
//        self.backgroundColor = theme.chatList.backgroundColor
//
//        self.chatListNode.updateThemeAndStrings(theme: theme, strings: strings, dateTimeFormat: dateTimeFormat, nameSortOrder: nameSortOrder, nameDisplayOrder: nameDisplayOrder, disableAnimations: disableAnimations)
//        self.searchDisplayController?.updateThemeAndStrings(theme: theme, strings: strings)
//        self.chatListEmptyNode?.updateThemeAndStrings(theme: theme, strings: strings)
//    }

    func containerLayoutUpdated(
        _ layout: ContainerViewLayout,
        navigationBarHeight: CGFloat,
        visualNavigationHeight: CGFloat,
        transition: ContainedViewLayoutTransition
    ) {
        self.containerLayout = (layout, navigationBarHeight, visualNavigationHeight)

        var insets = layout.insets(options: [.input])
        insets.top += max(navigationBarHeight, layout.insets(options: [.statusBar]).top)

        insets.left += layout.safeInsets.left
        insets.right += layout.safeInsets.right

        self.chatListNode.bounds = CGRect(x: 0.0, y: 0.0, width: layout.size.width, height: layout.size.height)
        self.chatListNode.position = CGPoint(x: layout.size.width / 2.0, y: layout.size.height / 2.0)

        var duration: Double = 0.0
        var curve: UInt = 0
        switch transition {
        case .immediate:
            break
        case let .animated(animationDuration, animationCurve):
            duration = animationDuration
            switch animationCurve {
                case .easeInOut, .custom:
                    break
                case .spring:
                    curve = 7
            }
        }

        let listViewCurve: ListViewAnimationCurve
        if curve == 7 {
            listViewCurve = .Spring(duration: duration)
        } else {
            listViewCurve = .Default(duration: duration)
        }

        let panelHeight = titlePanelNode.updateLayout(width: layout.size.width, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, transition: transition, theme: presentationData.theme, strings: presentationData.strings)

        var titlePanelFrame = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: layout.size.width, height: panelHeight))

        if !isTitlePanelShown {
            titlePanelFrame.origin.y -= panelHeight
        }
        
        transition.updateFrame(node: self.titlePanelNode, frame: titlePanelFrame)
        transition.updateFrame(node: self.titleAccessoryPanelContainer, frame: CGRect(origin: CGPoint(x: 0.0, y: insets.top), size: CGSize(width: layout.size.width, height: 56.0)))

        if isTitlePanelShown {
            insets.top += panelHeight
        }

        let updateSizeAndInsets = ListViewUpdateSizeAndInsets(size: layout.size, insets: insets, duration: duration, curve: listViewCurve)

        self.chatListNode.updateLayout(transition: transition, updateSizeAndInsets: updateSizeAndInsets)

        if let chatListEmptyNode = self.chatListEmptyNode {
            let emptySize = CGSize(width: updateSizeAndInsets.size.width, height: updateSizeAndInsets.size.height - updateSizeAndInsets.insets.top - updateSizeAndInsets.insets.bottom)
            transition.updateFrame(node: chatListEmptyNode, frame: CGRect(origin: CGPoint(x: 0.0, y: updateSizeAndInsets.insets.top), size: emptySize))
            chatListEmptyNode.updateLayout(size: emptySize, transition: transition)
        }

        if let searchDisplayController = self.searchDisplayController {
            searchDisplayController.containerLayoutUpdated(layout, navigationBarHeight: navigationBarHeight, transition: transition)
        }
    }

    func activateSearch() {
//        guard let (containerLayout, navigationBarHeight) = self.containerLayout, let navigationBar = self.navigationBar else {
//            return
//        }
//
//        var maybePlaceholderNode: SearchBarPlaceholderNode?
//        self.chatListNode.forEachItemNode { node in
//            if let node = node as? ChatListSearchItemNode {
//                maybePlaceholderNode = node.searchBarNode
//            }
//        }
//
//        if let _ = self.searchDisplayController {
//            return
//        }
//
//        if let placeholderNode = maybePlaceholderNode {
//            self.searchDisplayController = SearchDisplayController(presentationData: presentationData, mode: , contentNode: ChatListSearchContainerNode(account: self.account, filter: [], groupId: self.groupId, openPeer: { [weak self] peer, dismissSearch in
//                self?.requestOpenPeerFromSearch?(peer, dismissSearch)
//                }, openRecentPeerOptions: { [weak self] peer in
//                    self?.requestOpenRecentPeerOptions?(peer)
//                }, openMessage: { [weak self] peer, messageId in
//                    if let requestOpenMessageFromSearch = self?.requestOpenMessageFromSearch {
//                        requestOpenMessageFromSearch(peer, messageId)
//                    }
//                }, addContact: { [weak self] phoneNumber in
//                    if let requestAddContact = self?.requestAddContact {
//                        requestAddContact(phoneNumber)
//                    }
//            }), cancel: { [weak self] in
//                if let requestDeactivateSearch = self?.requestDeactivateSearch {
//                    requestDeactivateSearch()
//                }
//            })
//
//            self.searchDisplayController?.containerLayoutUpdated(containerLayout, navigationBarHeight: navigationBarHeight, transition: .immediate)
//            self.searchDisplayController?.activate(insertSubnode: { subnode, isSearchBar in
//                if let strongSelf = self, let strongPlaceholderNode = placeholderNode {
//                    if isSearchBar {
//                        strongPlaceholderNode.supernode?.insertSubnode(subnode, aboveSubnode: strongPlaceholderNode)
//                    } else {
//                        strongSelf.insertSubnode(subnode, belowSubnode: navigationBar)
//                    }
//                }
//                self.insertSubnode(subnode, belowSubnode: navigationBar)
//            }, placeholder: placeholderNode)
//        }
    }

    func deactivateSearch(animated: Bool) {
//        if let searchDisplayController = self.searchDisplayController {
//            var maybePlaceholderNode: SearchBarPlaceholderNode?
//            self.chatListNode.forEachItemNode { node in
//                if let node = node as? ChatListSearchItemNode {
//                    maybePlaceholderNode = node.searchBarNode
//                }
//            }
//
//            searchDisplayController.deactivate(placeholder: maybePlaceholderNode, animated: animated)
//            self.searchDisplayController = nil
//        }
    }
}

