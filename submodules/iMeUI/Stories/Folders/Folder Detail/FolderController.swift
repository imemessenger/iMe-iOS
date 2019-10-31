//
//  FolderController.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 30/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit
import Postbox
import SwiftSignalKit
import Display
import TelegramCore
import AccountContext
import TelegramPresentationData
import TelegramBaseController
import TelegramNotices
import AlertUI


public protocol ChatListItemNodeType: ASDisplayNode {
    var isDisplayingRevealedOptions: Bool { get }
    var chatListItemType: ChatListItemType? { get }
}

public protocol ChatListItemType {
    var iMeContent: IMEChatListItemContent { get }
}

public enum IMEChatListItemContent {
    case peer(RenderedPeer)
    case groupReference(PeerGroupId)
}

public final class FolderController: TelegramBaseController, UIViewControllerPreviewingDelegate {
    private var validLayout: ContainerViewLayout?

    private let context: AccountContext
    private let controlsHistoryPreload: Bool

    private let groupId: PeerGroupId = .root

    let openMessageFromSearchDisposable: MetaDisposable = MetaDisposable()

    private var chatListDisplayNode: FolderControllerNode {
        return super.displayNode as! FolderControllerNode
    }

    private let chatTitleView: _ChatTitleView

    private var proxyUnavailableTooltipController: TooltipController?
    private var didShowProxyUnavailableTooltipController = false

    private var dismissSearchOnDisappear = false

    private var didSetup3dTouch = false

    private var passcodeLockTooltipDisposable = MetaDisposable()
    private var didShowPasscodeLockTooltipController = false

    private var suggestLocalizationDisposable = MetaDisposable()
    private var didSuggestLocalization = false

    private var updateFolderActionDisposable = MetaDisposable()

    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?

    // MARK: -

    private var chatListModeSwitcher: ((ChatListMode) -> Void)?

    private let folder: Folder
    
    private let factory: FolderModuleFactory

    // MARK: -

    public init(context: AccountContext, controlsHistoryPreload: Bool, folderId: Folder.Id, factory: FolderModuleFactory) {
        self.factory = factory
        self.context = context
        self.controlsHistoryPreload = controlsHistoryPreload
        self.folder = context.account.postbox.folder(with: folderId)!

        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }

        self.chatTitleView = _ChatTitleView(account: context.account, theme: presentationData.theme, strings: presentationData.strings, dateTimeFormat: presentationData.dateTimeFormat)

        super.init(context: context, navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData), mediaAccessoryPanelVisibility: .always, locationBroadcastPanelSource: .summary)

        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style

        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        self.navigationItem.titleView = chatTitleView

        chatTitleView.folder = folder
        chatTitleView.pressed = { [weak self] in
            self?.chatListDisplayNode.isTitlePanelShown.toggle()
            self?.requestLayout(transition: .animated(duration: 0.2, curve: .spring))
        }

        self.scrollToTop = { [weak self] in
            self?.chatListDisplayNode.chatListNode.scrollToTop()
        }

        self.scrollToTopWithTabBar = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            if strongSelf.chatListDisplayNode.searchDisplayController != nil {
                strongSelf.deactivateSearch(animated: true)
            } else {
                strongSelf.chatListDisplayNode.chatListNode.scrollToTop()
            }
        }

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

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.openMessageFromSearchDisposable.dispose()
        self.passcodeLockTooltipDisposable.dispose()
        self.suggestLocalizationDisposable.dispose()
        self.presentationDataDisposable?.dispose()
    }

    private func updateThemeAndStrings() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)

        self.chatTitleView.updateThemeAndStrings(theme: presentationData.theme, strings: presentationData.strings)

        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: self.presentationData))

        if self.isNodeLoaded {
            self.chatListDisplayNode.updatePresentationData(self.presentationData)
        }
    }

    private func hideTitlePanel(animated: Bool = false) {
        chatListDisplayNode.isTitlePanelShown = false
        requestLayout(transition: animated ? .immediate : .animated(duration: 0.2, curve: .spring))
    }

    override public func loadDisplayNode() {
        let interaction = FolderInfoTitlePanelInteration(
            addMember: { [weak self] in
                self?.addPressed()
            }, edit: { [weak self] in
                self?.renamePressed()
                self?.hideTitlePanel(animated: true)
            }, delete: { [weak self] in
                self?.deletePressed()
            }
        )

        self.displayNode = FolderControllerNode(
            context: self.context,
            groupId: self.groupId,
            controlsHistoryPreload: self.controlsHistoryPreload,
            presentationData: self.presentationData,
            controller: self,
            factory: factory,
            setupChatListModeHandler: { [weak self, folder] in
                self?.chatListModeSwitcher = $0
                $0(.filter(type: .folder(folder)))
            },
            titlePanelInteraction: interaction
        )

        self.chatListDisplayNode.navigationBar = self.navigationBar

        self.chatListDisplayNode.requestDeactivateSearch = { }
        self.chatListDisplayNode.chatListNode.activateSearch = { }

        self.chatListDisplayNode.chatListNode.presentAlert = { [weak self] text in
            if let strongSelf = self {
                self?.present(standardTextAlertController(theme: AlertControllerTheme(presentationTheme: strongSelf.presentationData.theme), title: nil, text: text, actions: [TextAlertAction(type: .defaultAction, title: strongSelf.presentationData.strings.Common_OK, action: {})]), in: .window(.root))
            }
        }

        self.chatListDisplayNode.chatListNode.deletePeerChat = { [weak self, folder] peerId in
            guard let self = self else { return }

            let actionSheet = ActionSheetController(presentationTheme: self.presentationData.theme)

            actionSheet.setItemGroups([
                ActionSheetItemGroup(items: [
                    ActionSheetButtonItem(title: self.presentationData.strings.Folder_RemovePeer, color: .destructive) { [weak self, weak actionSheet, folder] in
                        actionSheet?.dismissAnimated()
                        self?.context.account.postbox.remove(peerWithId: peerId, from: folder)

                        if self?.folder.peerIds.isEmpty ?? true {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    }
                ]),
                ActionSheetItemGroup(items: [
                    ActionSheetButtonItem(title: self.presentationData.strings.Common_Cancel, color: .accent) { [weak actionSheet] in
                        actionSheet?.dismissAnimated()
                    }
                ])
            ])

            self.present(actionSheet, in: .window(.root))
        }

        self.chatListDisplayNode.chatListNode.peerSelected = { [weak self] peerId, animated, isAd in
            if let strongSelf = self {
                if let navigationController = strongSelf.navigationController as? NavigationController {
                    if isAd {
                        let _ = (ApplicationSpecificNotice.getProxyAdsAcknowledgment(accountManager: strongSelf.context.sharedContext.accountManager)
                            |> deliverOnMainQueue).start(next: { value in
                                guard let strongSelf = self else {
                                    return
                                }
                                if !value {
                                    strongSelf.present(textAlertController(context: strongSelf.context, title: nil, text: strongSelf.presentationData.strings.DialogList_AdNoticeAlert, actions: [TextAlertAction(type: .defaultAction, title: strongSelf.presentationData.strings.Common_OK, action: {
                                        if let strongSelf = self {
                                            let _ = ApplicationSpecificNotice.setProxyAdsAcknowledgment(accountManager: strongSelf.context.sharedContext.accountManager).start()
                                        }
                                    })]), in: .window(.root))
                                }
                            })
                    }

                    var scrollToEndIfExists = false
                    if let layout = strongSelf.validLayout, case .regular = layout.metrics.widthClass {
                        scrollToEndIfExists = true
                    }

                    if peerId.id < 0 {
                        guard let self = self else { return }
                        (self.navigationController as? NavigationController)?
                            .pushViewController(
                                FolderController(
                                    context: self.context,
                                    controlsHistoryPreload: false,
                                    folderId: -peerId.id,
                                    factory: self.factory
                                )
                        )
                    } else {
                        let params = NavigateToChatControllerParams(
                            navigationController: navigationController,
                            context: strongSelf.context,
                            chatLocation: .peer(peerId),
                            keepStack: .always,
                            scrollToEndIfExists: scrollToEndIfExists,
                            animated: animated,
                            options: strongSelf.groupId == PeerGroupId.root ? [.removeOnMasterDetails] : [],
                            parentGroupId: strongSelf.groupId,
                            completion: { [weak self] in
                                self?.chatListDisplayNode.chatListNode.clearHighlightAnimated(true)
                            },
                            showsUnreadCountOnBackButton: false
                        )
                        
                        self?.context.sharedContext.navigateToChatController(params)
                    }
                }
            }
        }

        self.chatListDisplayNode.chatListNode.groupSelected = { _ in }
        self.chatListDisplayNode.chatListNode.updatePeerGrouping = { _, _ in }
        self.chatListDisplayNode.requestOpenMessageFromSearch = { _, _ in }
        self.chatListDisplayNode.requestOpenPeerFromSearch = { _, _ in }
        self.chatListDisplayNode.requestOpenRecentPeerOptions = { _ in }
        self.chatListDisplayNode.requestAddContact = { _ in }

        self.displayNodeDidLoad()
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOSApplicationExtension 9.0, *) {
            if !self.didSetup3dTouch && self.traitCollection.forceTouchCapability != .unknown {
                self.didSetup3dTouch = true
                self.registerForPreviewingNonNative(with: self, sourceView: self.view, theme: PeekControllerTheme(presentationTheme: self.presentationData.theme))
            }
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

//        #if DEBUG
//        DispatchQueue.main.async {
//            let count = ChatControllerCount.with({ $0 })
//            if count != 0 {
//                self.present(standardTextAlertController(theme: AlertControllerTheme(presentationTheme: self.presentationData.theme), title: "", text: "ChatControllerCount \(count)", actions: [TextAlertAction(type: .defaultAction, title: "OK", action: {})]), in: .window(.root))
//            }
//        }
//        #endif

//        if let lockViewFrame = self.titleView.lockViewFrame, !self.didShowPasscodeLockTooltipController {
//            self.passcodeLockTooltipDisposable.set(combineLatest(queue: .mainQueue(), ApplicationSpecificNotice.getPasscodeLockTips(accountManager: self.context.sharedContext.accountManager), self.context.sharedContext.accountManager.accessChallengeData() |> take(1)).start(next: { [weak self] tooltipValue, passcodeView in
//                if let strongSelf = self {
//                    if !tooltipValue {
//                        let hasPasscode = passcodeView.data.isLockable
//                        if hasPasscode {
//                            let _ = ApplicationSpecificNotice.setPasscodeLockTips(accountManager: strongSelf.context.sharedContext.accountManager).start()
//
//                            let tooltipController = TooltipController(content: .text(strongSelf.presentationData.strings.DialogList_PasscodeLockHelp), dismissByTapOutside: true)
//                            strongSelf.present(tooltipController, in: .window(.root), with: TooltipControllerPresentationArguments(sourceViewAndRect: { [weak self] in
//                                if let strongSelf = self {
//                                    return (strongSelf.titleView, lockViewFrame.offsetBy(dx: 4.0, dy: 14.0))
//                                }
//                                return nil
//                            }))
//                            strongSelf.didShowPasscodeLockTooltipController = true
//                        }
//                    } else {
//                        strongSelf.didShowPasscodeLockTooltipController = true
//                    }
//                }
//            }))
//        }

//        if !self.didSuggestLocalization {
//            self.didSuggestLocalization = true
//
//            let network = self.context.account.network
//            let signal = combineLatest(self.context.sharedContext.accountManager.transaction { transaction -> String in
//                let languageCode: String
//                if let current = transaction.getSharedData(SharedDataKeys.localizationSettings) as? LocalizationSettings {
//                    let code = current.primaryComponent.languageCode
//                    let rawSuffix = "-raw"
//                    if code.hasSuffix(rawSuffix) {
//                        languageCode = String(code.dropLast(rawSuffix.count))
//                    } else {
//                        languageCode = code
//                    }
//                } else {
//                    languageCode = "en"
//                }
//                return languageCode
//            }, self.context.account.postbox.transaction { transaction -> SuggestedLocalizationEntry? in
//                var suggestedLocalization: SuggestedLocalizationEntry?
//                if let localization = transaction.getPreferencesEntry(key: PreferencesKeys.suggestedLocalization) as? SuggestedLocalizationEntry {
//                    suggestedLocalization = localization
//                }
//                return suggestedLocalization
//            })
//                |> mapToSignal({ value -> Signal<(String, SuggestedLocalizationInfo)?, NoError> in
//                    guard let suggestedLocalization = value.1, !suggestedLocalization.isSeen && suggestedLocalization.languageCode != "en" && suggestedLocalization.languageCode != value.0 else {
//                        return .single(nil)
//                    }
//                    return suggestedLocalizationInfo(network: network, languageCode: suggestedLocalization.languageCode, extractKeys: LanguageSuggestionControllerStrings.keys)
//                        |> map({ suggestedLocalization -> (String, SuggestedLocalizationInfo)? in
//                            return (value.0, suggestedLocalization)
//                        })
//                })
//
//            self.suggestLocalizationDisposable.set((signal |> deliverOnMainQueue).start(next: { [weak self] suggestedLocalization in
//                guard let strongSelf = self, let (currentLanguageCode, suggestedLocalization) = suggestedLocalization else {
//                    return
//                }
//                if let controller = languageSuggestionController(context: strongSelf.context, suggestedLocalization: suggestedLocalization, currentLanguageCode: currentLanguageCode, openSelection: { [weak self] in
//                    if let strongSelf = self {
//                        let controller = LocalizationListController(context: strongSelf.context)
//                        (strongSelf.navigationController as? NavigationController)?.pushViewController(controller)
//                    }
//                }) {
//                    strongSelf.present(controller, in: .window(.root))
//                    _ = markSuggestedLocalizationAsSeenInteractively(postbox: strongSelf.context.account.postbox, languageCode: suggestedLocalization.languageCode).start()
//                }
//            }))
//        }
//
//        self.chatListDisplayNode.chatListNode.addedVisibleChatsWithPeerIds = { [weak self] peerIds in
//            guard let strongSelf = self else {
//                return
//            }
//
//            strongSelf.forEachController({ controller in
//                if let controller = controller as? UndoOverlayController {
//                    switch controller.content {
//                    case let .archivedChat(archivedChat):
//                        if peerIds.contains(archivedChat.peerId) {
//                            controller.dismiss()
//                        }
//                    default:
//                        break
//                    }
//                }
//                return true
//            })
//        }
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if self.dismissSearchOnDisappear {
            self.dismissSearchOnDisappear = false
            self.deactivateSearch(animated: false)
        }

        self.chatListDisplayNode.isTitlePanelShown = false
        self.chatListDisplayNode.chatListNode.clearHighlightAnimated(true)
    }

    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)

        self.validLayout = layout

        self.chatListDisplayNode.containerLayoutUpdated(layout, navigationBarHeight: self.navigationHeight, visualNavigationHeight: self.navigationHeight, transition: transition)
    }

    override public func navigationStackConfigurationUpdated(next: [ViewController]) {
        super.navigationStackConfigurationUpdated(next: next)

        let chatLocation = (next.first as? ChatController)?.chatLocation

        self.chatListDisplayNode.chatListNode.updateSelectedChatLocation(chatLocation, progress: 1.0, transition: .immediate)
    }

    private func addPressed() {
        let controller = ChatListSelectionController(context: context, options: [], filters: [.excludeSelf, .exclude(folder.peerIds.collect())], createsFolder: false)
        updateFolderActionDisposable.set(
            (controller.result |> deliverOnMainQueue)
                .start(next: { [context, folder] selectedPeers in
                    let peerIds = selectedPeers.compactMap { (peerSelection) -> PeerId? in
                        if case let .peer(peerId) = peerSelection {
                            return peerId
                        } else {
                            return nil
                        }
                    }

                    context.account.postbox.add(peerIds: peerIds, to: folder)

                    controller.navigationController?.popViewController(animated: true)
                })
        )
        (self.navigationController as? NavigationController)?.pushViewController(controller, animated: true)
    }

    private func renamePressed() {
        let alert = _standardTextAlertController(
            theme: .init(presentationTheme: presentationData.theme),
            title: nil,
            text: presentationData.strings.Folder_RenameFolder,
            inputPlaceholder: presentationData.strings.Folder_NewName,
            renameAction: { [weak self] in
                guard let self = self else { return }
                guard !$0.isEmpty else { return self.showEmptyNameError() }

                self.context.account.postbox.rename(folder: self.folder, to: $0)
                self.chatTitleView.updateTitle()
            },
                        
            keyboardColor: presentationData.theme.rootController.keyboardColor,
            placeholderColor: presentationData.theme.chat.inputPanel.inputPlaceholderColor,
            primaryTextColor: presentationData.theme.chat.inputPanel.primaryTextColor
        )

        present(alert, in: .window(.root))
    }

    private func showEmptyNameError() {
        let alert = standardTextAlertController(
            theme: .init(presentationTheme: presentationData.theme),
            title: nil,
            text: presentationData.strings.Folder_EmptyError,
            actions: [
                TextAlertAction.init(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})
            ]
        )

        present(alert, in: .window(.root))
    }

    private func deletePressed() {
        context.account.postbox.delete(folderWithId: folder.id)
        navigationController?.popViewController(animated: true)
    }

    func activateSearch() {
//        tabBarView.isHidden = true
//        tabBarView.alpha = 0.0

        if self.displayNavigationBar {
            let _ = (self.chatListDisplayNode.chatListNode.ready
                |> take(1)
                |> deliverOnMainQueue).start(completed: { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    if let scrollToTop = strongSelf.scrollToTop {
                        scrollToTop()
                    }
                    strongSelf.chatListDisplayNode.activateSearch()
                    strongSelf.setDisplayNavigationBar(false, transition: .animated(duration: 0.5, curve: .spring))
                })
        }
    }

    func deactivateSearch(animated: Bool) {
//        tabBarView.isHidden = false
//        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions.curveEaseInOut, animations: { [weak self] in
//            self?.tabBarView.alpha = 1.0
//        })

        if !self.displayNavigationBar {
            self.setDisplayNavigationBar(true, transition: animated ? .animated(duration: 0.5, curve: .spring) : .immediate)
            self.chatListDisplayNode.deactivateSearch(animated: animated)
            self.scrollToTop?()
        }
    }

    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if #available(iOSApplicationExtension 9.0, *) {
            if let (controller, rect) = self.previewingController(from: previewingContext.sourceView, for: location) {
                previewingContext.sourceRect = rect
                return controller
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    func previewingController(from sourceView: UIView, for location: CGPoint) -> (UIViewController, CGRect)? {
        guard let layout = self.validLayout, case .compact = layout.metrics.widthClass else {
            return nil
        }

        let boundsSize = self.view.bounds.size
        let contentSize: CGSize

        if case .unknown = layout.deviceMetrics {
            contentSize = boundsSize
        } else {
            contentSize = layout.deviceMetrics.previewingContentSize(inLandscape: boundsSize.width > boundsSize.height)
        }

        if let searchController = self.chatListDisplayNode.searchDisplayController {
            if let (view, bounds, action) = searchController.previewViewAndActionAtLocation(location) {
                if let peerId = action as? PeerId, peerId.namespace != Namespaces.Peer.SecretChat {
                    var sourceRect = view.superview!.convert(view.frame, to: sourceView)
                    sourceRect = CGRect(x: sourceRect.minX, y: sourceRect.minY + bounds.minY, width: bounds.width, height: bounds.height)
                    sourceRect.size.height -= UIScreenPixel

                    let chatController = self.context.sharedContext.makeChatController(context: self.context, chatLocation: .peer(peerId), subject: nil, botStart: nil, mode: .standard(previewing: true))
                    chatController.canReadHistory.set(false)

                    chatController.containerLayoutUpdated(ContainerViewLayout(size: contentSize, metrics: LayoutMetrics(), deviceMetrics: layout.deviceMetrics, intrinsicInsets: UIEdgeInsets(), safeInsets: UIEdgeInsets(), statusBarHeight: nil, inputHeight: nil, inputHeightIsInteractivellyChanging: false, inVoiceOver: false), transition: .immediate)
                    return (chatController, sourceRect)
                } else if let messageId = action as? MessageId, messageId.peerId.namespace != Namespaces.Peer.SecretChat {
                    var sourceRect = view.superview!.convert(view.frame, to: sourceView)
                    sourceRect = CGRect(x: sourceRect.minX, y: sourceRect.minY + bounds.minY, width: bounds.width, height: bounds.height)
                    sourceRect.size.height -= UIScreenPixel

                    let chatController = self.context.sharedContext.makeChatController(context: self.context, chatLocation: .peer(messageId.peerId), subject: .message(messageId), botStart: nil, mode: .standard(previewing: true))
                    chatController.canReadHistory.set(false)
                    chatController.containerLayoutUpdated(ContainerViewLayout(size: contentSize, metrics: LayoutMetrics(), deviceMetrics: layout.deviceMetrics, intrinsicInsets: UIEdgeInsets(), safeInsets: UIEdgeInsets(), statusBarHeight: nil, inputHeight: nil, inputHeightIsInteractivellyChanging: false, inVoiceOver: false), transition: .immediate)
                    return (chatController, sourceRect)
                }
            }
            return nil
        }

        let listLocation = self.view.convert(location, to: self.chatListDisplayNode.chatListNode.view)
        
        var selectedNode: ChatListItemNodeType?

        self.chatListDisplayNode.chatListNode.forEachItemNode { itemNode in
            if let itemNode = itemNode as? ChatListItemNodeType, itemNode.frame.contains(listLocation), !itemNode.isDisplayingRevealedOptions {
                selectedNode = itemNode
            }
        }
        
        if let selectedNode = selectedNode, let item = selectedNode.chatListItemType {
            var sourceRect = selectedNode.view.superview!.convert(selectedNode.frame, to: sourceView)
            sourceRect.size.height -= UIScreenPixel
            switch item.iMeContent {
            case let .peer(peer):
                if peer.peerId.namespace != Namespaces.Peer.SecretChat && !peer.peerId.isFolderId {
                    let chatController = self.context.sharedContext.makeChatController(
                        context: self.context,
                        chatLocation: .peer(peer.peerId),
                        subject: nil,
                        botStart: nil,
                        mode: .standard(previewing: true)
                    )

                    chatController.canReadHistory.set(false)
                    
                    chatController.containerLayoutUpdated(
                        ContainerViewLayout(
                            size: contentSize,
                            metrics: LayoutMetrics(),
                            deviceMetrics: layout.deviceMetrics,
                            intrinsicInsets: UIEdgeInsets(),
                            safeInsets: UIEdgeInsets(),
                            statusBarHeight: nil,
                            inputHeight: nil,
                            inputHeightIsInteractivellyChanging: false,
                            inVoiceOver: false
                        ),
                        transition: .immediate
                    )
                    
//                    chatController.containerLayoutUpdated(ContainerViewLayout(size: contentSize, metrics: LayoutMetrics(), intrinsicInsets: UIEdgeInsets(), safeInsets: UIEdgeInsets(), statusBarHeight: nil, inputHeight: nil, standardInputHeight: 216.0, inputHeightIsInteractivellyChanging: false, inVoiceOver: false), transition: .immediate)
                    return (chatController, sourceRect)
                } else {
                    return nil
                }
            case let .groupReference(groupId):
                let chatListController = self.context.sharedContext.makeChatListController(
                    context: self.context,
                    groupId: groupId,
                    controlsHistoryPreload: false,
                    hideNetworkActivityStatus: false,
                    enableDebugActions: false
                )
                
                chatListController.containerLayoutUpdated(
                    ContainerViewLayout(
                        size: contentSize,
                        metrics: LayoutMetrics(),
                        deviceMetrics: layout.deviceMetrics,
                        intrinsicInsets: UIEdgeInsets(),
                        safeInsets: UIEdgeInsets(),
                        statusBarHeight: nil,
                        inputHeight: nil,
                        inputHeightIsInteractivellyChanging: false,
                        inVoiceOver: false
                    ),
                    transition: .immediate
                )
                
//                let chatListController = ChatListController(context: self.context, groupId: groupId, controlsHistoryPreload: false)
//                chatListController.containerLayoutUpdated(ContainerViewLayout(size: contentSize, metrics: LayoutMetrics(), intrinsicInsets: UIEdgeInsets(), safeInsets: UIEdgeInsets(), statusBarHeight: nil, inputHeight: nil, standardInputHeight: 216.0, inputHeightIsInteractivellyChanging: false, inVoiceOver: false), transition: .immediate)
                return (chatListController, sourceRect)
            }
//            case let .peer(_, peer, _, _, _, _, _, _, _, _):
//                if peer.peerId.namespace != Namespaces.Peer.SecretChat && !peer.peerId.isFolderId {
//                    let chatController = ChatController(context: self.context, chatLocation: .peer(peer.peerId), mode: .standard(previewing: true))
//                    chatController.canReadHistory.set(false)
//                    chatController.containerLayoutUpdated(ContainerViewLayout(size: contentSize, metrics: LayoutMetrics(), intrinsicInsets: UIEdgeInsets(), safeInsets: UIEdgeInsets(), statusBarHeight: nil, inputHeight: nil, standardInputHeight: 216.0, inputHeightIsInteractivellyChanging: false, inVoiceOver: false), transition: .immediate)
//                    return (chatController, sourceRect)
//                } else {
//                    return nil
//                }
//            case let .groupReference(groupId, _, _, _, _):
//                let chatListController = ChatListController(context: self.context, groupId: groupId, controlsHistoryPreload: false)
//                chatListController.containerLayoutUpdated(ContainerViewLayout(size: contentSize, metrics: LayoutMetrics(), intrinsicInsets: UIEdgeInsets(), safeInsets: UIEdgeInsets(), statusBarHeight: nil, inputHeight: nil, standardInputHeight: 216.0, inputHeightIsInteractivellyChanging: false, inVoiceOver: false), transition: .immediate)
//                return (chatListController, sourceRect)
//            }
        } else {
            return nil
        }
        
//        return nil
    }

    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.previewingCommit(viewControllerToCommit)
    }

    func previewingCommit(_ viewControllerToCommit: UIViewController) {
        if let viewControllerToCommit = viewControllerToCommit as? ViewController {
            if let chatController = viewControllerToCommit as? ChatController {
                chatController.canReadHistory.set(true)
                chatController.updatePresentationMode(.standard(previewing: false))
                if let navigationController = self.navigationController as? NavigationController {
                    
                    var scrollToEndIfExists = false
                    if let layout = validLayout, case .regular = layout.metrics.widthClass {
                        scrollToEndIfExists = true
                    }
                    
                    let params = NavigateToChatControllerParams(
                        navigationController: navigationController,
                        context: context,
                        chatLocation: chatController.chatLocation,
                        scrollToEndIfExists: scrollToEndIfExists,
                        options: groupId == PeerGroupId.root ? [.removeOnMasterDetails] : [], // новое
                        parentGroupId: groupId,
                        completion: { [weak self] in
                            self?.chatListDisplayNode.chatListNode.clearHighlightAnimated(true)
                        }
                    )
                    
                    self.context.sharedContext.navigateToChatController(params)
                }
            } else if let chatListController = viewControllerToCommit as? ChatListController {
                if let navigationController = self.navigationController as? NavigationController {
                    navigationController.pushViewController(chatListController, animated: false, completion: {})
                    self.chatListDisplayNode.chatListNode.clearHighlightAnimated(true)
                }
            }
        }
    }

    override public var keyShortcuts: [KeyShortcut] {
        return []
    }

    private func _standardTextAlertController(
        theme: AlertControllerTheme,
        title: String?,
        text: String,
        inputPlaceholder: String,
        renameAction: @escaping (String) -> Void,
        keyboardColor: PresentationThemeKeyboardColor,
        placeholderColor: UIColor,
        primaryTextColor: UIColor
    ) -> AlertController {
        var dismissImpl: (() -> Void)?
        var renameImpl: (() -> Void)?

        let actions = [
            TextAlertAction.init(type: .defaultAction, title: presentationData.strings.Folder_Confirm, action: {
                renameImpl?()
            }),
            TextAlertAction.init(type: .genericAction, title: presentationData.strings.Common_Cancel, action: { })
        ]

        let contentNode = _TextAlertContentNode(
            theme: theme,
            title: title != nil ? NSAttributedString(string: title!, font: Font.medium(17.0), textColor: theme.primaryColor, paragraphAlignment: .center) : nil,
            text: NSAttributedString(string: text, font: title == nil ? Font.semibold(17.0) : Font.regular(13.0),
                                     textColor: theme.primaryColor, paragraphAlignment: .center),
            inputPlaceholder: inputPlaceholder,
            actions: actions.map { action in
                return TextAlertAction(type: action.type, title: action.title, action: {
                    action.action()
                    dismissImpl?()
                })
            },
            actionLayout: .horizontal,
            keyboardColor: keyboardColor,
            placeholderColor: placeholderColor,
            primaryTextColor: primaryTextColor
        )

        let controller = AlertController(
            theme: theme,
            contentNode: contentNode
        )

        renameImpl = { [weak contentNode] in
            renameAction(contentNode?.name ?? "")
        }

        dismissImpl = { [weak controller] in
            controller?.dismissAnimated()
        }

        return controller
    }
}

// MARK: -

private final class TextAlertContentActionNode: HighlightableButtonNode {
    private let backgroundNode: ASDisplayNode

    let action: TextAlertAction

    init(theme: AlertControllerTheme, action: TextAlertAction) {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        self.backgroundNode.backgroundColor = theme.highlightedItemColor
        self.backgroundNode.alpha = 0.0

        self.action = action

        super.init()

        self.titleNode.maximumNumberOfLines = 2
        var font = Font.regular(17.0)
        var color = theme.accentColor
        switch action.type {
        case .defaultAction, .genericAction:
            break
        case .destructiveAction:
            color = theme.destructiveColor
        }
        switch action.type {
        case .defaultAction:
            font = Font.semibold(17.0)
        case .destructiveAction, .genericAction:
            break
        }
        self.setAttributedTitle(NSAttributedString(string: action.title, font: font, textColor: color, paragraphAlignment: .center), for: [])

        self.highligthedChanged = { [weak self] value in
            if let strongSelf = self {
                if value {
                    if strongSelf.backgroundNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.backgroundNode, at: 0)
                    }
                    strongSelf.backgroundNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.backgroundNode.alpha = 1.0
                } else if !strongSelf.backgroundNode.alpha.isZero {
                    strongSelf.backgroundNode.alpha = 0.0
                    strongSelf.backgroundNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.25)
                }
            }
        }
    }

    override func didLoad() {
        super.didLoad()

        self.addTarget(self, action: #selector(self.pressed), forControlEvents: .touchUpInside)
    }

    @objc func pressed() {
        self.action.action()
    }

    override func layout() {
        super.layout()

        self.backgroundNode.frame = self.bounds
    }
}


public final class _TextAlertContentNode: AlertContentNode {
    private let theme: AlertControllerTheme
    private let actionLayout: TextAlertContentActionLayout

    private let titleNode: ASTextNode?
    private let textNode: ImmediateTextNode
    private let inputNode: TextFieldNode

    private let actionNodesSeparator: ASDisplayNode
    private let actionNodes: [TextAlertContentActionNode]
    private let actionVerticalSeparators: [ASDisplayNode]

    var name: String?

    public var textAttributeAction: (NSAttributedString.Key, (Any) -> Void)? {
        didSet {
            if let (attribute, textAttributeAction) = self.textAttributeAction {
                self.textNode.highlightAttributeAction = { attributes in
                    if let _ = attributes[attribute] {
                        return attribute
                    } else {
                        return nil
                    }
                }
                self.textNode.tapAttributeAction = { attributes in
                    if let value = attributes[attribute] {
                        textAttributeAction(value)
                    }
                }
                self.textNode.linkHighlightColor = self.theme.accentColor.withAlphaComponent(0.5)
            } else {
                self.textNode.highlightAttributeAction = nil
                self.textNode.tapAttributeAction = nil
            }
        }
    }

    public init(theme: AlertControllerTheme, title: NSAttributedString?, text: NSAttributedString, inputPlaceholder: String, actions: [TextAlertAction], actionLayout: TextAlertContentActionLayout, keyboardColor: PresentationThemeKeyboardColor, placeholderColor: UIColor, primaryTextColor: UIColor) {
        self.theme = theme
        self.actionLayout = actionLayout
        if let title = title {
            let titleNode = ASTextNode()
            titleNode.attributedText = title
            titleNode.displaysAsynchronously = false
            titleNode.isUserInteractionEnabled = false
            titleNode.maximumNumberOfLines = 1
            titleNode.truncationMode = .byTruncatingTail
            self.titleNode = titleNode
        } else {
            self.titleNode = nil
        }

        self.textNode = ImmediateTextNode()
        self.textNode.maximumNumberOfLines = 0
        self.textNode.attributedText = text
        self.textNode.displaysAsynchronously = false
        self.textNode.isLayerBacked = false
        if text.length != 0 {
            if let paragraphStyle = text.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
                self.textNode.textAlignment = paragraphStyle.alignment
            }
        }

        self.inputNode = TextFieldNode()
        self.inputNode.textField.placeholder = inputPlaceholder
        self.inputNode.textField.font = Font.regular(15.0)
        self.inputNode.textField.textColor = primaryTextColor
        self.inputNode.textField.tintColor = theme.accentColor
        self.inputNode.textField.autocorrectionType = .no
        self.inputNode.textField.returnKeyType = .done
        self.inputNode.textField.textAlignment = .natural
//        self.inputNode.textField.contentInsets = .szero
        self.inputNode.textField.attributedPlaceholder = NSAttributedString(string: inputPlaceholder, font: Font.regular(15.0), textColor: placeholderColor)
//        self.inputNode.textField.borderStyle = .roundedRect
        switch keyboardColor {
            case .light:
                self.inputNode.textField.keyboardAppearance = .default
            case .dark:
                self.inputNode.textField.keyboardAppearance = .dark
        }

//        self.firstNameField = TextFieldNode()
//        self.firstNameField.textField.font = Font.regular(20.0)
//        self.firstNameField.textField.textColor = self.theme.primaryColor
//        self.firstNameField.textField.textAlignment = .natural
//        self.firstNameField.textField.returnKeyType = .next
//        self.firstNameField.textField.attributedPlaceholder = NSAttributedString(string: self.strings.UserInfo_FirstNamePlaceholder, font: self.firstNameField.textField.font, textColor: self.theme.textPlaceholderColor)
//        self.firstNameField.textField.autocapitalizationType = .words
//        self.firstNameField.textField.autocorrectionType = .no
//        if #available(iOSApplicationExtension 10.0, *) {
//            self.firstNameField.textField.textContentType = .givenName
//        }
//
//        self.lastNameField = TextFieldNode()
//        self.lastNameField.textField.font = Font.regular(20.0)
//        self.lastNameField.textField.textColor = self.theme.primaryColor
//        self.lastNameField.textField.textAlignment = .natural
//        self.lastNameField.textField.returnKeyType = .done
//        self.lastNameField.textField.attributedPlaceholder = NSAttributedString(string: strings.UserInfo_LastNamePlaceholder, font: self.lastNameField.textField.font, textColor: self.theme.textPlaceholderColor)
//        self.lastNameField.textField.autocapitalizationType = .words
//        self.lastNameField.textField.autocorrectionType = .no
//        if #available(iOSApplicationExtension 10.0, *) {
//            self.lastNameField.textField.textContentType = .familyName
//        }


        self.actionNodesSeparator = ASDisplayNode()
        self.actionNodesSeparator.isLayerBacked = true
        self.actionNodesSeparator.backgroundColor = theme.separatorColor

        self.actionNodes = actions.map { action -> TextAlertContentActionNode in
            return TextAlertContentActionNode(theme: theme, action: action)
        }

        var actionVerticalSeparators: [ASDisplayNode] = []
        if actions.count > 1 {
            for _ in 0 ..< actions.count - 1 {
                let separatorNode = ASDisplayNode()
                separatorNode.isLayerBacked = true
                separatorNode.backgroundColor = theme.separatorColor
                actionVerticalSeparators.append(separatorNode)
            }
        }
        self.actionVerticalSeparators = actionVerticalSeparators

        super.init()

        self.inputNode.textField.delegate = self
        self.inputNode.textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)

        if let titleNode = self.titleNode {
            self.addSubnode(titleNode)
        }
        self.addSubnode(self.textNode)
        self.addSubnode(self.inputNode)

        self.addSubnode(self.actionNodesSeparator)

        for actionNode in self.actionNodes {
            self.addSubnode(actionNode)
        }

        for separatorNode in self.actionVerticalSeparators {
            self.addSubnode(separatorNode)
        }
    }

    override public func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) -> CGSize {
        let insets = UIEdgeInsets(top: 18.0, left: 18.0, bottom: 18.0, right: 18.0)

        var titleSize: CGSize?
        if let titleNode = self.titleNode {
            titleSize = titleNode.measure(CGSize(width: size.width - insets.left - insets.right, height: CGFloat.greatestFiniteMagnitude))
        }
        let textSize = self.textNode.updateLayout(CGSize(width: size.width - insets.left - insets.right, height: CGFloat.greatestFiniteMagnitude))
        let inputSize = CGSize(width: textSize.width, height: 44.0)

        let actionButtonHeight: CGFloat = 44.0

        var minActionsWidth: CGFloat = 0.0
        let maxActionWidth: CGFloat = floor(size.width / CGFloat(self.actionNodes.count))
        let actionTitleInsets: CGFloat = 8.0

        var effectiveActionLayout = self.actionLayout
        for actionNode in self.actionNodes {
            let actionTitleSize = actionNode.titleNode.measure(CGSize(width: maxActionWidth, height: actionButtonHeight))
            if case .horizontal = effectiveActionLayout, actionTitleSize.height > actionButtonHeight * 0.6667 {
                effectiveActionLayout = .vertical
            }
            switch effectiveActionLayout {
            case .horizontal:
                minActionsWidth += actionTitleSize.width + actionTitleInsets
            case .vertical:
                minActionsWidth = max(minActionsWidth, actionTitleSize.width + actionTitleInsets)
            }
        }

        let resultSize: CGSize

        var actionsHeight: CGFloat = 0.0
        switch effectiveActionLayout {
        case .horizontal:
            actionsHeight = actionButtonHeight
        case .vertical:
            actionsHeight = actionButtonHeight * CGFloat(self.actionNodes.count)
        }

        if let titleNode = titleNode, let titleSize = titleSize {
            var contentWidth = max(max(titleSize.width, textSize.width), minActionsWidth)
            contentWidth = max(contentWidth, 150.0)

            let spacing: CGFloat = 6.0
            let titleFrame = CGRect(origin: CGPoint(x: insets.left + floor((contentWidth - titleSize.width) / 2.0), y: insets.top), size: titleSize)
            transition.updateFrame(node: titleNode, frame: titleFrame)

            let textFrame = CGRect(origin: CGPoint(x: insets.left + floor((contentWidth - textSize.width) / 2.0), y: titleFrame.maxY + spacing), size: textSize)
            transition.updateFrame(node: self.textNode, frame: textFrame)

            let inputFrame = CGRect(origin: CGPoint(x: textFrame.origin.x, y: textFrame.maxY + spacing), size: inputSize)
            transition.updateFrame(node: self.inputNode, frame: inputFrame)

            resultSize = CGSize(width: contentWidth + insets.left + insets.right, height: titleSize.height + spacing + textSize.height + spacing + inputSize.height + actionsHeight + insets.top + insets.bottom)
        } else {
            var contentWidth = max(textSize.width, minActionsWidth)
            contentWidth = max(contentWidth, 150.0)

            let spacing: CGFloat = 6.0
            let textFrame = CGRect(origin: CGPoint(x: insets.left + floor((contentWidth - textSize.width) / 2.0), y: insets.top), size: textSize)
            transition.updateFrame(node: self.textNode, frame: textFrame)

            let inputFrame = CGRect(origin: CGPoint(x: textFrame.origin.x, y: textFrame.maxY + spacing), size: inputSize)
            transition.updateFrame(node: self.inputNode, frame: inputFrame)

            resultSize = CGSize(width: contentWidth + insets.left + insets.right, height: textSize.height + inputSize.height + actionsHeight + insets.top + insets.bottom)
        }

        self.actionNodesSeparator.frame = CGRect(origin: CGPoint(x: 0.0, y: resultSize.height - actionsHeight - UIScreenPixel), size: CGSize(width: resultSize.width, height: UIScreenPixel))

        var actionOffset: CGFloat = 0.0
        let actionWidth: CGFloat = floor(resultSize.width / CGFloat(self.actionNodes.count))
        var separatorIndex = -1
        var nodeIndex = 0
        for actionNode in self.actionNodes {
            if separatorIndex >= 0 {
                let separatorNode = self.actionVerticalSeparators[separatorIndex]
                switch effectiveActionLayout {
                case .horizontal:
                    transition.updateFrame(node: separatorNode, frame: CGRect(origin: CGPoint(x: actionOffset - UIScreenPixel, y: resultSize.height - actionsHeight), size: CGSize(width: UIScreenPixel, height: actionsHeight - UIScreenPixel)))
                case .vertical:
                    transition.updateFrame(node: separatorNode, frame: CGRect(origin: CGPoint(x: 0.0, y: resultSize.height - actionsHeight + actionOffset - UIScreenPixel), size: CGSize(width: resultSize.width, height: UIScreenPixel)))
                }
            }
            separatorIndex += 1

            let currentActionWidth: CGFloat
            switch effectiveActionLayout {
            case .horizontal:
                if nodeIndex == self.actionNodes.count - 1 {
                    currentActionWidth = resultSize.width - actionOffset
                } else {
                    currentActionWidth = actionWidth
                }
            case .vertical:
                currentActionWidth = resultSize.width
            }

            let actionNodeFrame: CGRect
            switch effectiveActionLayout {
            case .horizontal:
                actionNodeFrame = CGRect(origin: CGPoint(x: actionOffset, y: resultSize.height - actionsHeight), size: CGSize(width: currentActionWidth, height: actionButtonHeight))
                actionOffset += currentActionWidth
            case .vertical:
                actionNodeFrame = CGRect(origin: CGPoint(x: 0.0, y: resultSize.height - actionsHeight + actionOffset), size: CGSize(width: currentActionWidth, height: actionButtonHeight))
                actionOffset += actionButtonHeight
            }

            transition.updateFrame(node: actionNode, frame: actionNodeFrame)

            nodeIndex += 1
        }

        return resultSize
    }

    @objc
    private func textDidChange() {
        name = inputNode.textField.text
    }

}

extension _TextAlertContentNode: UITextFieldDelegate {

    public func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        return range.location + range.length <= 24
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.actionNodes.first?.action.action()
        return true
    }

}
