//
//  ChatListSelectionListNode.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 18/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import Display
import AsyncDisplayKit
import SwiftSignalKit
import Postbox
import TelegramCore
import AccountContext
import TelegramPresentationData
import ChatListSearchItemNode
import ChatListSearchItemHeader
import SearchUI
import ContactsPeerItem
import TelegramUIPreferences
import MergeLists
import ContactListUI

//import Contac

private enum ChatListSelectionNodeEntryId: Hashable {
    case search
    case option(index: Int)
    case peerId(Int64)
    case deviceContact(DeviceContactStableId)
    
    var hashValue: Int {
        switch self {
        case .search:
            return 0
        case let .option(index):
            return (index + 2).hashValue
        case let .peerId(peerId):
            return peerId.hashValue
        case let .deviceContact(id):
            return id.hashValue
        }
    }
    
    static func <(lhs: ChatListSelectionNodeEntryId, rhs: ChatListSelectionNodeEntryId) -> Bool {
        return lhs.hashValue < rhs.hashValue
    }
    
    static func ==(lhs: ChatListSelectionNodeEntryId, rhs: ChatListSelectionNodeEntryId) -> Bool {
        switch lhs {
        case .search:
            switch rhs {
            case .search:
                return true
            default:
                return false
            }
        case let .option(index):
            if case .option(index) = rhs {
                return true
            } else {
                return false
            }
        case let .peerId(lhsId):
            switch rhs {
            case let .peerId(rhsId):
                return lhsId == rhsId
            default:
                return false
            }
        case let .deviceContact(id):
            if case .deviceContact(id) = rhs {
                return true
            } else {
                return false
            }
        }
    }
}

private final class ChatListSelectionNodeInteraction {
    let activateSearch: () -> Void
    let openPeer: (ChatListSelectionPeer) -> Void
    
    init(activateSearch: @escaping () -> Void, openPeer: @escaping (ChatListSelectionPeer) -> Void) {
        self.activateSearch = activateSearch
        self.openPeer = openPeer
    }
}

public enum ChatListSelectionPeerId: Hashable {
    case peer(PeerId)
    case deviceContact(DeviceContactStableId)
}

enum ChatListSelectionPeer: Equatable {
    case peer(peer: Peer, isGlobal: Bool)
    case deviceContact(DeviceContactStableId, DeviceContactBasicData)
    
    var id: ChatListSelectionPeerId {
        switch self {
        case let .peer(peer, _):
            return .peer(peer.id)
        case let .deviceContact(id, _):
            return .deviceContact(id)
        }
    }
    
    var indexName: PeerIndexNameRepresentation {
        switch self {
        case let .peer(peer, _):
            return peer.indexName
        case let .deviceContact(_, contact):
            return .personName(first: contact.firstName, last: contact.lastName, addressName: "", phoneNumber: "")
        }
    }
    
    static func ==(lhs: ChatListSelectionPeer, rhs: ChatListSelectionPeer) -> Bool {
        switch lhs {
        case let .peer(lhsPeer, lhsIsGlobal):
            if case let .peer(rhsPeer, rhsIsGlobal) = rhs, lhsPeer.isEqual(rhsPeer), lhsIsGlobal == rhsIsGlobal {
                return true
            } else {
                return false
            }
        case let .deviceContact(id, contact):
            if case .deviceContact(id, contact) = rhs {
                return true
            } else {
                return false
            }
        }
    }
}

private enum ChatListSelectionNodeEntry: Comparable, Identifiable {
    case search(PresentationTheme, PresentationStrings)
    case option(Int, ChatListSelectionAdditionalOption, PresentationTheme, PresentationStrings)
    case peer(Int, ChatListSelectionPeer, PeerPresence?, ListViewItemHeader?, ContactsPeerItemSelection, PresentationTheme, PresentationStrings, PresentationDateTimeFormat, PresentationPersonNameOrder, PresentationPersonNameOrder, Bool)
    
    var stableId: ChatListSelectionNodeEntryId {
        switch self {
        case .search:
            return .search
        case let .option(index, _, _, _):
            return .option(index: index)
        case let .peer(_, peer, _, _, _, _, _, _, _, _, _):
            switch peer {
            case let .peer(peer, _):
                return .peerId(peer.id.toInt64())
            case let .deviceContact(id, _):
                return .deviceContact(id)
            }
        }
    }
    
    func item(account: Account, interaction: ChatListSelectionNodeInteraction) -> ListViewItem {
        switch self {
        case let .search(theme, strings):
            return ChatListSearchItem(theme: theme, placeholder: strings.Contacts_SearchLabel, activate: {
                interaction.activateSearch()
            })
        case let .option(_, option, theme, _):
            return ContactListActionItem(theme: theme, title: option.title, icon: .generic(option.icon!), header: nil, action: option.action)
        case let .peer(_, peer, presence, header, selection, theme, strings, dateTimeFormat, nameSortOrder, nameDisplayOrder, enabled):
            let status: ContactsPeerItemStatus
            let itemPeer: ContactsPeerItemPeer
            switch peer {
            case let .peer(peer, isGlobal):
//                if isGlobal, let _ = peer.addressName {
//                    status = .addressName("")
//                } else {
//                    let presence = presence ?? TelegramUserPresence(status: .none, lastActivity: 0)
//                    status = .presence(presence, dateTimeFormat)
//                }
                status = .none
                itemPeer = .peer(peer: peer, chatPeer: peer)
            case let .deviceContact(id, contact):
                status = .none
                itemPeer = .deviceContact(stableId: id, contact: contact)
            }
            return ContactsPeerItem(theme: theme, strings: strings, sortOrder: nameSortOrder, displayOrder: nameDisplayOrder, account: account, peerMode: .peer, peer: itemPeer, status: status, enabled: enabled, selection: selection, editing: ContactsPeerItemEditing(editable: false, editing: false, revealed: false), index: nil, header: header, action: { _ in
                interaction.openPeer(peer)
            })
        }
    }
    
    static func ==(lhs: ChatListSelectionNodeEntry, rhs: ChatListSelectionNodeEntry) -> Bool {
        switch lhs {
        case let .search(lhsTheme, lhsStrings):
            if case let .search(rhsTheme, rhsStrings) = rhs, lhsTheme === rhsTheme, lhsStrings === rhsStrings {
                return true
            } else {
                return false
            }
        case let .option(lhsIndex, lhsOption, lhsTheme, lhsStrings):
            if case let .option(rhsIndex, rhsOption, rhsTheme, rhsStrings) = rhs, lhsIndex == rhsIndex, lhsOption == rhsOption, lhsTheme === rhsTheme, lhsStrings === rhsStrings {
                return true
            } else {
                return false
            }
        case let .peer(lhsIndex, lhsPeer, lhsPresence, lhsHeader, lhsSelection, lhsTheme, lhsStrings, lhsTimeFormat, lhsSortOrder, lhsDisplayOrder, lhsEnabled):
            switch rhs {
            case let .peer(rhsIndex, rhsPeer, rhsPresence, rhsHeader, rhsSelection, rhsTheme, rhsStrings, rhsTimeFormat, rhsSortOrder, rhsDisplayOrder, rhsEnabled):
                if lhsIndex != rhsIndex {
                    return false
                }
                if lhsPeer != rhsPeer {
                    return false
                }
                if let lhsPresence = lhsPresence, let rhsPresence = rhsPresence {
                    if !lhsPresence.isEqual(to: rhsPresence) {
                        return false
                    }
                } else if (lhsPresence != nil) != (rhsPresence != nil) {
                    return false
                }
                if lhsHeader?.id != rhsHeader?.id {
                    return false
                }
                if lhsSelection != rhsSelection {
                    return false
                }
                if lhsTheme !== rhsTheme {
                    return false
                }
                if lhsStrings !== rhsStrings {
                    return false
                }
                if lhsTimeFormat != rhsTimeFormat {
                    return false
                }
                if lhsSortOrder != rhsSortOrder {
                    return false
                }
                if lhsDisplayOrder != rhsDisplayOrder {
                    return false
                }
                if lhsEnabled != rhsEnabled {
                    return false
                }
                return true
            default:
                return false
            }
        }
    }
    
    static func <(lhs: ChatListSelectionNodeEntry, rhs: ChatListSelectionNodeEntry) -> Bool {
        switch lhs {
        case .search:
            return true
        case let .option(lhsIndex, _, _, _):
            switch rhs {
            case .search:
                return false
            case let .option(rhsIndex, _, _, _):
                return lhsIndex < rhsIndex
            case .peer:
                return true
            }
        case let .peer(lhsIndex, _, _, _, _, _, _, _, _, _, _):
            switch rhs {
            case .search, .option:
                return false
            case let .peer(rhsIndex, _, _, _, _, _, _, _, _, _, _):
                return lhsIndex < rhsIndex
            }
        }
    }
}

private extension PeerIndexNameRepresentation {
    func isLessThan(other: PeerIndexNameRepresentation, ordering: PresentationPersonNameOrder) -> ComparisonResult {
        switch self {
        case let .title(lhsTitle, _):
            switch other {
            case let .title(title, _):
                return lhsTitle.compare(title)
            case let .personName(_, last, _, _):
                let lastResult = lhsTitle.compare(last)
                if lastResult == .orderedSame {
                    return .orderedAscending
                } else {
                    return lastResult
                }
            }
        case let .personName(lhsFirst, lhsLast, _, _):
            switch other {
            case let .title(title, _):
                let lastResult = lhsFirst.compare(title)
                if lastResult == .orderedSame {
                    return .orderedDescending
                } else {
                    return lastResult
                }
            case let .personName(first, last, _, _):
                switch ordering {
                case .firstLast:
                    let firstResult = lhsFirst.compare(first)
                    if firstResult == .orderedSame {
                        return lhsLast.compare(last)
                    } else {
                        return firstResult
                    }
                case .lastFirst:
                    let lastResult = lhsLast.compare(last)
                    if lastResult == .orderedSame {
                        return lhsFirst.compare(first)
                    } else {
                        return lastResult
                    }
                }
            }
        }
    }
}

private func ChatListSelectionNodeEntries(accountPeer: Peer?, peers: [ChatListSelectionPeer], presences: [PeerId: PeerPresence], presentation: ChatListSelectionPresentation, selectionState: ChatListSelectionNodeGroupSelectionState?, theme: PresentationTheme, strings: PresentationStrings, dateTimeFormat: PresentationDateTimeFormat, sortOrder: PresentationPersonNameOrder, displayOrder: PresentationPersonNameOrder, disabledPeerIds:Set<PeerId>) -> [ChatListSelectionNodeEntry] {
    var entries: [ChatListSelectionNodeEntry] = []
    
    var orderedPeers: [ChatListSelectionPeer]
    var headers: [ChatListSelectionPeerId: ContactListNameIndexHeader] = [:]
    
    switch presentation {
    case let .orderedByPresence(options):
        entries.append(.search(theme, strings))
        orderedPeers = peers.sorted(by: { lhs, rhs in
            if case let .peer(lhsPeer, _) = lhs, case let .peer(rhsPeer, _) = rhs {
                let lhsPresence = presences[lhsPeer.id]
                let rhsPresence = presences[rhsPeer.id]
                if let lhsPresence = lhsPresence as? TelegramUserPresence, let rhsPresence = rhsPresence as? TelegramUserPresence {
                    if lhsPresence.status < rhsPresence.status {
                        return false
                    } else if lhsPresence.status > rhsPresence.status {
                        return true
                    }
                } else if let _ = lhsPresence {
                    return true
                } else if let _ = rhsPresence {
                    return false
                }
                return lhsPeer.id < rhsPeer.id
            } else if case .peer = lhs {
                return true
            } else {
                return false
            }
        })
        for i in 0 ..< options.count {
            entries.append(.option(i, options[i], theme, strings))
        }
    case let .natural(displaySearch, options):
        orderedPeers = peers.sorted {
            $0.indexName.mainName.capitalized < $1.indexName.mainName.capitalized
        }

//        print(">>>>>>")
//        orderedPeers.forEach { some in
//            switch some {
//                case let .peer(peer, _):
//                    print(peer.indexName)
//                case .deviceContact(_, _):
//                    break
//            }
//        }
//        print("<<<<<<<")

        var headerCache: [unichar: ContactListNameIndexHeader] = [:]
        for peer in orderedPeers {
            let indexHeader: unichar = peer.indexName.mainName.capitalized.utf16.first ?? 35
            let header: ContactListNameIndexHeader
            if let cached = headerCache[indexHeader] {
                header = cached
            } else {
                header = ContactListNameIndexHeader(theme: theme, letter: indexHeader)
                headerCache[indexHeader] = header
            }
            headers[peer.id] = header
        }
        if displaySearch {
            entries.append(.search(theme, strings))
        }
        for i in 0 ..< options.count {
            entries.append(.option(i, options[i], theme, strings))
        }
    case .search:
        orderedPeers = peers
    }
    
    var removeIndices: [Int] = []
    for i in 0 ..< orderedPeers.count {
        switch orderedPeers[i].indexName {
        case let .title(title, _):
            if title.isEmpty {
                removeIndices.append(i)
            }
        case let .personName(first, last, _, _):
            if first.isEmpty && last.isEmpty {
                removeIndices.append(i)
            }
        }
    }
    if !removeIndices.isEmpty {
        for index in removeIndices.reversed() {
            orderedPeers.remove(at: index)
        }
    }
    
    var commonHeader: ListViewItemHeader?
    switch presentation {
    case .orderedByPresence:
        commonHeader = ChatListSearchItemHeader(type: .contacts, theme: theme, strings: strings, actionTitle: nil, action: nil)
    default:
        break
    }
    
    for i in 0 ..< orderedPeers.count {
        let selection: ContactsPeerItemSelection
        if let selectionState = selectionState {
            selection = .selectable(selected: selectionState.selectedPeerIndices[orderedPeers[i].id] != nil)
        } else {
            selection = .none
        }
        let header: ListViewItemHeader?
        switch presentation {
        case .orderedByPresence:
            header = commonHeader
        default:
            header = headers[orderedPeers[i].id]
        }
        var presence: PeerPresence?
        if case let .peer(peer, _) = orderedPeers[i] {
            presence = presences[peer.id]
        }
        let enabled: Bool
        switch orderedPeers[i] {
        case let .peer(peer, _):
            enabled = !disabledPeerIds.contains(peer.id)
        default:
            enabled = true
        }
        entries.append(.peer(i, orderedPeers[i], presence, header, selection, theme, strings, dateTimeFormat, sortOrder, displayOrder, enabled))
    }
    return entries
}

private func preparedChatListSelectionNodeTransition(account: Account, from fromEntries: [ChatListSelectionNodeEntry], to toEntries: [ChatListSelectionNodeEntry], interaction: ChatListSelectionNodeInteraction, firstTime: Bool, animated: Bool) -> ChatListSelectionNodeTransition {
    let (deleteIndices, indicesAndItems, updateIndices) = mergeListsStableWithUpdates(leftList: fromEntries, rightList: toEntries)
    
    let deletions = deleteIndices.map { ListViewDeleteItem(index: $0, directionHint: nil) }
    let insertions = indicesAndItems.map { ListViewInsertItem(index: $0.0, previousIndex: $0.2, item: $0.1.item(account: account, interaction: interaction), directionHint: nil) }
    let updates = updateIndices.map { ListViewUpdateItem(index: $0.0, previousIndex: $0.2, item: $0.1.item(account: account, interaction: interaction), directionHint: nil) }
    
    return ChatListSelectionNodeTransition(deletions: deletions, insertions: insertions, updates: updates, firstTime: firstTime, animated: animated)
}

private struct ChatListSelectionNodeTransition {
    let deletions: [ListViewDeleteItem]
    let insertions: [ListViewInsertItem]
    let updates: [ListViewUpdateItem]
    let firstTime: Bool
    let animated: Bool
}

public struct ChatListSelectionAdditionalOption: Equatable {
    public let title: String
    public let icon: UIImage?
    public let action: () -> Void
    
    public static func ==(lhs: ChatListSelectionAdditionalOption, rhs: ChatListSelectionAdditionalOption) -> Bool {
        return lhs.title == rhs.title && lhs.icon === rhs.icon
    }
}

enum ChatListSelectionPresentation {
    case orderedByPresence(options: [ChatListSelectionAdditionalOption])
    case natural(displaySearch: Bool, options: [ChatListSelectionAdditionalOption])
    case search(signal: Signal<String, NoError>, searchDeviceContacts: Bool)
}

struct ChatListSelectionNodeGroupSelectionState: Equatable {
    let selectedPeerIndices: [ChatListSelectionPeerId: Int]
    let nextSelectionIndex: Int
    
    private init(selectedPeerIndices: [ChatListSelectionPeerId: Int], nextSelectionIndex: Int) {
        self.selectedPeerIndices = selectedPeerIndices
        self.nextSelectionIndex = nextSelectionIndex
    }
    
    init() {
        self.selectedPeerIndices = [:]
        self.nextSelectionIndex = 0
    }
    
    func withToggledPeerId(_ peerId: ChatListSelectionPeerId) -> ChatListSelectionNodeGroupSelectionState {
        var updatedIndices = self.selectedPeerIndices
        if let _ = updatedIndices[peerId] {
            updatedIndices.removeValue(forKey: peerId)
            return ChatListSelectionNodeGroupSelectionState(selectedPeerIndices: updatedIndices, nextSelectionIndex: self.nextSelectionIndex)
        } else {
            updatedIndices[peerId] = self.nextSelectionIndex
            return ChatListSelectionNodeGroupSelectionState(selectedPeerIndices: updatedIndices, nextSelectionIndex: self.nextSelectionIndex + 1)
        }
    }
}

public enum ChatListSelectionFilter {
    case excludeSelf
    case exclude([PeerId])
    case disable([PeerId])
}

final class ChatListSelectionNode: ASDisplayNode {
    private let context: AccountContext
    private var account: Account { return context.account }
    private let presentation: ChatListSelectionPresentation
    private let filters: [ChatListSelectionFilter]
    
    let listNode: ListView
    
    private var queuedTransitions: [ChatListSelectionNodeTransition] = []
    private var hasValidLayout = false
    
    private var _ready = ValuePromise<Bool>()
    var ready: Signal<Bool, NoError> {
        return self._ready.get()
    }
    private var didSetReady = false
    
    private let chatListViewPromise = Promise<ChatListView>()
    
    private let selectionStatePromise = Promise<ChatListSelectionNodeGroupSelectionState?>(nil)
    private var selectionStateValue: ChatListSelectionNodeGroupSelectionState? {
        didSet {
            self.selectionStatePromise.set(.single(self.selectionStateValue))
        }
    }
    
    private var enableUpdatesValue = false
    var enableUpdates: Bool {
        get {
            return self.enableUpdatesValue
        } set(value) {
            if value != self.enableUpdatesValue {
                self.enableUpdatesValue = value
                self.chatListViewPromise.set(
                    self.account.postbox.tailChatListView(groupId: .root, count: 0, summaryComponents: .init())
                        |> map { $0.0 }
                        |> take(1)
                )
            }
        }
    }
    
    var activateSearch: (() -> Void)?
    var openPeer: ((ChatListSelectionPeer) -> Void)?
    
    private let previousEntries = Atomic<[ChatListSelectionNodeEntry]?>(value: nil)
    private let disposable = MetaDisposable()
    
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    private let themeAndStringsPromise: Promise<(PresentationTheme, PresentationStrings, PresentationDateTimeFormat, PresentationPersonNameOrder, PresentationPersonNameOrder, Bool)>

    init(context: AccountContext, presentation: ChatListSelectionPresentation, filters: [ChatListSelectionFilter] = [.excludeSelf], selectionState: ChatListSelectionNodeGroupSelectionState? = nil) {
        self.context = context
        self.presentation = presentation
        self.filters = filters

        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        self.listNode = ListView()
        self.listNode.dynamicBounceEnabled = !self.presentationData.disableAnimations
        
        self.themeAndStringsPromise = Promise((self.presentationData.theme, self.presentationData.strings, self.presentationData.dateTimeFormat, self.presentationData.nameSortOrder, self.presentationData.nameDisplayOrder, self.presentationData.disableAnimations))
        
        super.init()
        
        self.backgroundColor = self.presentationData.theme.chatList.backgroundColor
        
        self.selectionStateValue = selectionState
        self.selectionStatePromise.set(.single(selectionState))
        
        self.addSubnode(self.listNode)
        
        let processingQueue = Queue()
        let previousEntries = Atomic<[ChatListSelectionNodeEntry]?>(value: nil)
        
        let interaction = ChatListSelectionNodeInteraction(activateSearch: { [weak self] in
            self?.activateSearch?()
            }, openPeer: { [weak self] peer in
                self?.openPeer?(peer)
        })
        
        let account = self.account
        var firstTime: Int32 = 1
        let selectionStateSignal = self.selectionStatePromise.get()
        let transition: Signal<ChatListSelectionNodeTransition, NoError>
        let themeAndStringsPromise = self.themeAndStringsPromise

        transition = (combineLatest(self.chatListViewPromise.get(), selectionStateSignal, themeAndStringsPromise.get())
            |> mapToQueue { view, selectionState, themeAndStrings -> Signal<ChatListSelectionNodeTransition, NoError> in
                let signal = deferred { () -> Signal<ChatListSelectionNodeTransition, NoError> in
                    var peers = view.entries
                        .compactMap {
                            switch $0 {
                                case let .MessageEntry(_, _, _, _, _, renderedPeer, _, _):
                                    return renderedPeer.peer
                                default:
                                    return nil
                            }
                        }
                        .map({ ChatListSelectionPeer.peer(peer: $0, isGlobal: false) })
                    var existingPeerIds = Set<PeerId>()
                    var disabledPeerIds = Set<PeerId>()
                    for filter in filters {
                        switch filter {
                        case .excludeSelf:
                            existingPeerIds.insert(account.peerId)
                        case let .exclude(peerIds):
                            existingPeerIds = existingPeerIds.union(peerIds)
                        case let .disable(peerIds):
                            disabledPeerIds = disabledPeerIds.union(peerIds)
                        }
                    }

                    peers = peers.filter { contact in
                        switch contact {
                        case let .peer(peer, _):
                            return !existingPeerIds.contains(peer.id)
                        default:
                            return true
                        }
                    }

                    let entries = ChatListSelectionNodeEntries(accountPeer: nil/*view.accountPeer*/, peers: peers, presences: [:]/*view.peerPresences*/, presentation: presentation, selectionState: selectionState, theme: themeAndStrings.0, strings: themeAndStrings.1, dateTimeFormat: themeAndStrings.2, sortOrder: themeAndStrings.3, displayOrder: themeAndStrings.4, disabledPeerIds: disabledPeerIds)
                    let previous = previousEntries.swap(entries)
                    let animated: Bool
                    if let previous = previous, !themeAndStrings.5 {
                        animated = (entries.count - previous.count) < 20
                    } else {
                        animated = false
                    }
                    return .single(preparedChatListSelectionNodeTransition(account: account, from: previous ?? [], to: entries, interaction: interaction, firstTime: previous == nil, animated: animated))
                }

                if OSAtomicCompareAndSwap32(1, 0, &firstTime) {
                    return signal |> runOn(Queue.mainQueue())
                } else {
                    return signal |> runOn(processingQueue)
                }
            })
            |> deliverOnMainQueue

        self.disposable.set(transition.start(next: { [weak self] transition in
            self?.enqueueTransition(transition)
        }))
        
        self.presentationDataDisposable = (context.sharedContext.presentationData
            |> deliverOnMainQueue).start(next: { [weak self] presentationData in
                if let strongSelf = self {
                    let previousTheme = strongSelf.presentationData.theme
                    let previousStrings = strongSelf.presentationData.strings
                    let previousDisableAnimations = strongSelf.presentationData.disableAnimations
                    
                    strongSelf.presentationData = presentationData
                    
                    if previousTheme !== presentationData.theme || previousStrings !== presentationData.strings || previousDisableAnimations != presentationData.disableAnimations {
                        strongSelf.backgroundColor = presentationData.theme.chatList.backgroundColor
                        strongSelf.themeAndStringsPromise.set(.single((presentationData.theme, presentationData.strings, presentationData.dateTimeFormat, presentationData.nameSortOrder, presentationData.nameDisplayOrder, presentationData.disableAnimations)))
                        
                        strongSelf.listNode.dynamicBounceEnabled = !presentationData.disableAnimations
                        
                        strongSelf.listNode.forEachAccessoryItemNode({ accessoryItemNode in
                            if let accessoryItemNode = accessoryItemNode as? ContactsSectionHeaderAccessoryItemNode {
                                accessoryItemNode.updateTheme(theme: presentationData.theme)
                            }
                        })
                        
                        strongSelf.listNode.forEachItemHeaderNode({ itemHeaderNode in
                            if let itemHeaderNode = itemHeaderNode as? ContactListNameIndexHeaderNode {
                                itemHeaderNode.updateTheme(theme: presentationData.theme)
                            } else if let itemHeaderNode = itemHeaderNode as? ChatListSearchItemHeaderNode {
                                itemHeaderNode.updateTheme(theme: presentationData.theme)
                            }
                        })
                    }
                }
            })
        
        self.listNode.didEndScrolling = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            fixSearchableListNodeScrolling(strongSelf.listNode)
        }
        
        self.enableUpdates = true
    }
    
    deinit {
        self.disposable.dispose()
        self.presentationDataDisposable?.dispose()
    }
    
    func updateSelectionState(_ f: (ChatListSelectionNodeGroupSelectionState?) -> ChatListSelectionNodeGroupSelectionState?) {
        let updatedSelectionState = f(self.selectionStateValue)
        if updatedSelectionState != self.selectionStateValue {
            self.selectionStateValue = updatedSelectionState
        }
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        var insets = layout.insets(options: [.input])
        insets.left += layout.safeInsets.left
        insets.right += layout.safeInsets.right
        
        self.listNode.bounds = CGRect(x: 0.0, y: 0.0, width: layout.size.width, height: layout.size.height)
        self.listNode.position = CGPoint(x: layout.size.width / 2.0, y: layout.size.height / 2.0)
        
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
        
        let updateSizeAndInsets = ListViewUpdateSizeAndInsets(size: layout.size, insets: insets, duration: duration, curve: listViewCurve)
        
        self.listNode.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: [.Synchronous, .LowLatency], scrollToItem: nil, updateSizeAndInsets: updateSizeAndInsets, stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
        
        if !self.hasValidLayout {
            self.hasValidLayout = true
            self.dequeueTransitions()
        }
    }
    
    private func enqueueTransition(_ transition: ChatListSelectionNodeTransition) {
        self.queuedTransitions.append(transition)
        
        if self.hasValidLayout {
            self.dequeueTransitions()
        }
    }
    
    private func dequeueTransitions() {
        if self.hasValidLayout {
            while !self.queuedTransitions.isEmpty {
                let transition = self.queuedTransitions.removeFirst()
                
                var options = ListViewDeleteAndInsertOptions()
                if transition.firstTime {
                    options.insert(.Synchronous)
                    options.insert(.LowLatency)
                } else if transition.animated {
                    if case .orderedByPresence = self.presentation {
                        options.insert(.AnimateCrossfade)
                    }
                }
                self.listNode.transaction(deleteIndices: transition.deletions, insertIndicesAndItems: transition.insertions, updateIndicesAndItems: transition.updates, options: options, updateOpaqueState: nil, completion: { [weak self] _ in
                    if let strongSelf = self {
                        if !strongSelf.didSetReady {
                            strongSelf.didSetReady = true
                            strongSelf._ready.set(true)
                        }
                    }
                })
            }
        }
    }
    
    func scrollToTop() {
        self.listNode.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: [.Synchronous, .LowLatency], scrollToItem: ListViewScrollToItem(index: 0, position: .top(0.0), animated: true, curve: .Default(duration: nil), directionHint: .Up), updateSizeAndInsets: nil, stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
    }
}

private extension PeerIndexNameRepresentation {
    var mainName: String {
        switch self {
            case let .title(title, _):
                return title
            case let .personName(first, _, _, _):
                return first
        }
    }
}
