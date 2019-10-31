//
//
//  ChatListSelectionController.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 17/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import Display
import AsyncDisplayKit
import Postbox
import SwiftSignalKit
import TelegramCore
import AccountContext
import CounterContollerTitleView
import TelegramPresentationData
import ProgressNavigationButtonNode

public final class ChatListSelectionController: ViewController {
    private let context: AccountContext

    private let titleView: CounterContollerTitleView

    private var chatsNode: ChatSelectionControllerNode {
        return self.displayNode as! ChatSelectionControllerNode
    }

    var dismissed: (() -> Void)?

    private let index: PeerNameIndex = .lastNameFirst

    private var _ready = Promise<Bool>()
    private var _limitsReady = Promise<Bool>()
    private var _listReady = Promise<Bool>()
    override public var ready: Promise<Bool> {
        return self._ready
    }

    private let _result = Promise<[ChatListSelectionPeerId]>()
    public var result: Signal<[ChatListSelectionPeerId], NoError> {
        return self._result.get()
    }

    private var rightNavigationButton: UIBarButtonItem?

    var displayProgress: Bool = false {
        didSet {
            if self.displayProgress != oldValue {
                if self.displayProgress {
                    let item = UIBarButtonItem(customDisplayNode: ProgressNavigationButtonNode(color: self.presentationData.theme.rootController.navigationBar.accentTextColor))
                    self.navigationItem.rightBarButtonItem = item
                } else {
                    self.navigationItem.rightBarButtonItem = self.rightNavigationButton
                }
            }
        }
    }

    private var didPlayPresentationAnimation = false

    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?

    private var limitsConfiguration: LimitsConfiguration?
    private var limitsConfigurationDisposable: Disposable?
    private let options: [ChatListSelectionAdditionalOption]
    private let filters: [ChatListSelectionFilter]

    private let createsFolder: Bool

    public init(context: AccountContext, options: [ChatListSelectionAdditionalOption], filters: [ChatListSelectionFilter] = [.excludeSelf], createsFolder: Bool = true) {
        self.context = context
        self.options = options
        self.filters = filters
        self.createsFolder = createsFolder
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }

        self.titleView = CounterContollerTitleView(theme: self.presentationData.theme)

        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))

        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style

        self.navigationItem.titleView = self.titleView
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)

        self.scrollToTop = { [weak self] in
            if let strongSelf = self {
                strongSelf.chatsNode.contactListNode.scrollToTop()
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

        self.limitsConfigurationDisposable = (context.account.postbox.transaction { transaction -> LimitsConfiguration in
            return currentLimitsConfiguration(transaction: transaction)
            } |> deliverOnMainQueue).start(next: { [weak self] value in
                if let strongSelf = self {
                    strongSelf.limitsConfiguration = value
                    strongSelf.updateTitle()
                    strongSelf._limitsReady.set(.single(true))
                }
            })

        self._ready.set(combineLatest(self._listReady.get(), self._limitsReady.get()) |> map { $0 && $1 })
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.presentationDataDisposable?.dispose()
        self.limitsConfigurationDisposable?.dispose()
    }

    private func updateThemeAndStrings() {
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: self.presentationData))
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        self.updateTitle()
    }

    private func updateTitle() {
        let title = createsFolder
            ? self.presentationData.strings.ComposeFolder_CreateFolder
            : self.presentationData.strings.ComposeFolder_AddChats
        self.titleView.title = CounterContollerTitle(title: title, counter: "0")

        let buttonText = createsFolder ? self.presentationData.strings.Common_Next : self.presentationData.strings.Common_Done
        let rightNavigationButton = UIBarButtonItem(title: buttonText, style: .done, target: self, action: #selector(self.rightNavigationButtonPressed))
        self.rightNavigationButton = rightNavigationButton
        self.navigationItem.rightBarButtonItem = self.rightNavigationButton
        rightNavigationButton.isEnabled = false
    }

    override public func loadDisplayNode() {
        self.displayNode = ChatSelectionControllerNode(context: self.context, options: self.options, filters: filters)
        self._listReady.set(self.chatsNode.contactListNode.ready)

        self.chatsNode.dismiss = { [weak self] in
            self?.presentingViewController?.dismiss(animated: true, completion: nil)
        }

        self.chatsNode.openPeer = { [weak self] peer in
            if let strongSelf = self, case let .peer(peer, _) = peer {
                var updatedCount: Int?

                let maxRegularCount: Int32 = strongSelf.limitsConfiguration?.maxGroupMemberCount ?? 200
                var displayCountAlert = false

                var selectionState: ChatListSelectionNodeGroupSelectionState?
                strongSelf.chatsNode.contactListNode.updateSelectionState { state in
                    if let state = state {
                        var updatedState = state.withToggledPeerId(.peer(peer.id))
                        if updatedState.selectedPeerIndices.count >= maxRegularCount {
                            displayCountAlert = true
                            updatedState = updatedState.withToggledPeerId(.peer(peer.id))
                        }
                        updatedCount = updatedState.selectedPeerIndices.count
                        selectionState = updatedState
                        return updatedState
                    } else {
                        return nil
                    }
                }
//                if let searchResultsNode = strongSelf.chatsNode.searchResultsNode {
//                    searchResultsNode.updateSelectionState { _ in
//                        return selectionState
//                    }
//                }

                if let updatedCount = updatedCount {
                    strongSelf.rightNavigationButton?.isEnabled = updatedCount != 0
                    strongSelf.titleView.title = CounterContollerTitle(title: strongSelf.presentationData.strings.ComposeFolder_CreateFolder, counter: "\(updatedCount)")
                }

                strongSelf.requestLayout(transition: ContainedViewLayoutTransition.animated(duration: 0.4, curve: .spring))

                if displayCountAlert {
                    strongSelf.present(standardTextAlertController(theme: AlertControllerTheme(presentationTheme: strongSelf.presentationData.theme), title: nil, text: strongSelf.presentationData.strings.CreateGroup_SoftUserLimitAlert, actions: [TextAlertAction(type: .defaultAction, title: strongSelf.presentationData.strings.Common_OK, action: {})]), in: .window(.root))
                }
            }
        }

        self.chatsNode.removeSelectedPeer = { [weak self] peerId in
            if let strongSelf = self {
                var updatedCount: Int?

                var selectionState: ChatListSelectionNodeGroupSelectionState?
                strongSelf.chatsNode.contactListNode.updateSelectionState { state in
                    if let state = state {
                        let updatedState = state.withToggledPeerId(peerId)
                        updatedCount = updatedState.selectedPeerIndices.count
                        selectionState = updatedState
                        return updatedState
                    } else {
                        return nil
                    }
                }
//                if let searchResultsNode = strongSelf.chatsNode.searchResultsNode {
//                    searchResultsNode.updateSelectionState { _ in
//                        return selectionState
//                    }
//                }

                if let updatedCount = updatedCount {
                    strongSelf.rightNavigationButton?.isEnabled = updatedCount != 0
                }

                strongSelf.requestLayout(transition: ContainedViewLayoutTransition.animated(duration: 0.4, curve: .spring))
            }
        }

        self.displayNodeDidLoad()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.chatsNode.contactListNode.enableUpdates = true
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let presentationArguments = self.presentationArguments as? ViewControllerPresentationArguments, !self.didPlayPresentationAnimation {
            self.didPlayPresentationAnimation = true
            if case .modalSheet = presentationArguments.presentationAnimation {
                self.chatsNode.animateIn()
            }
        }
    }

    override public func dismiss(completion: (() -> Void)? = nil) {
        if let presentationArguments = self.presentationArguments as? ViewControllerPresentationArguments {
            switch presentationArguments.presentationAnimation {
            case .modalSheet:
                self.dismissed?()
                self.chatsNode.animateOut(completion: completion)
            case .none:
                self.dismissed?()
                completion?()
            }
        }
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.chatsNode.contactListNode.enableUpdates = false
    }

    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)

        self.chatsNode.containerLayoutUpdated(layout, navigationBarHeight: self.navigationHeight, actualNavigationBarHeight: self.navigationHeight, transition: transition)
    }

    @objc func cancelPressed() {
        self._result.set(.single([]))
        self.dismiss()
    }

    @objc func rightNavigationButtonPressed() {
        var peerIds: [ChatListSelectionPeerId] = []
        self.chatsNode.contactListNode.updateSelectionState { state in
            if let state = state {
                peerIds = Array(state.selectedPeerIndices.keys)
            }
            return state
        }
        self._result.set(.single(peerIds))
    }
}
