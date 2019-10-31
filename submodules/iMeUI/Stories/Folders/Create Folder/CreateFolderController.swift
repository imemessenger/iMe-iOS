//
//  CreateFolderController.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 17/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import LegacyComponents
import ItemListAvatarAndNameInfoItem
import ItemListUI
import TelegramPresentationData
import ItemListPeerItem
import AccountContext

private struct CreateFolderArguments {
    let account: Account

    let updateEditingName: (ItemListAvatarAndNameInfoItemName) -> Void
    let done: () -> Void
    let changeProfilePhoto: () -> Void
}

private enum CreateFolderSection: Int32 {
    case info
    case members
}

private enum CreateFolderEntryTag: ItemListItemTag {
    case info

    func isEqual(to other: ItemListItemTag) -> Bool {
        if let other = other as? CreateFolderEntryTag {
            switch self {
            case .info:
                if case .info = other {
                    return true
                } else {
                    return false
                }
            }
        } else {
            return false
        }
    }
}

private enum CreateFolderEntry: ItemListNodeEntry {
    case groupInfo(PresentationTheme, PresentationStrings, PresentationDateTimeFormat, Peer?, ItemListAvatarAndNameInfoItemState, ItemListAvatarAndNameInfoItemUpdatingAvatar?)

    case member(Int32, PresentationTheme, PresentationStrings, PresentationDateTimeFormat, Peer, PeerPresence?)

    var section: ItemListSectionId {
        switch self {
        case .groupInfo:
            return CreateFolderSection.info.rawValue
        case .member:
            return CreateFolderSection.members.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .groupInfo:
            return 0
        case let .member(index, _, _, _, _, _):
            return 1 + index
        }
    }

    static func ==(lhs: CreateFolderEntry, rhs: CreateFolderEntry) -> Bool {
        switch lhs {
        case let .groupInfo(lhsTheme, lhsStrings, lhsDateTimeFormat, lhsPeer, lhsEditingState, lhsAvatar):
            if case let .groupInfo(rhsTheme, rhsStrings, rhsDateTimeFormat, rhsPeer, rhsEditingState, rhsAvatar) = rhs {
                if lhsTheme !== rhsTheme {
                    return false
                }
                if lhsStrings !== rhsStrings {
                    return false
                }
                if lhsDateTimeFormat != rhsDateTimeFormat {
                    return false
                }
                if let lhsPeer = lhsPeer, let rhsPeer = rhsPeer {
                    if !lhsPeer.isEqual(rhsPeer) {
                        return false
                    }
                } else if (lhsPeer != nil) != (rhsPeer != nil) {
                    return false
                }
                if lhsEditingState != rhsEditingState {
                    return false
                }
                if lhsAvatar != rhsAvatar {
                    return false
                }
                return true
            } else {
                return false
            }
        case let .member(lhsIndex, lhsTheme, lhsStrings, lhsDateTimeFormat, lhsPeer, lhsPresence):
            if case let .member(rhsIndex, rhsTheme, rhsStrings, rhsDateTimeFormat, rhsPeer, rhsPresence) = rhs {
                if lhsIndex != rhsIndex {
                    return false
                }
                if lhsTheme !== rhsTheme {
                    return false
                }
                if lhsStrings !== rhsStrings {
                    return false
                }
                if lhsDateTimeFormat != rhsDateTimeFormat {
                    return false
                }
                if !lhsPeer.isEqual(rhsPeer) {
                    return false
                }
                if let lhsPresence = lhsPresence, let rhsPresence = rhsPresence {
                    if !lhsPresence.isEqual(to: rhsPresence) {
                        return false
                    }
                } else if (lhsPresence != nil) != (rhsPresence != nil) {
                    return false
                }
                return true
            } else {
                return false
            }
        }
    }

    static func <(lhs: CreateFolderEntry, rhs: CreateFolderEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(_ arguments: CreateFolderArguments) -> ListViewItem {
        switch self {
        case let .groupInfo(theme, strings, dateTimeFormat, peer, state, avatar):
            return ItemListAvatarAndNameInfoItem(
                account: arguments.account,
                theme: theme,
                strings: strings,
                dateTimeFormat: dateTimeFormat,
                mode: .generic,
                peer: peer,
                presence: nil,
                cachedData: nil,
                state: state,
                sectionId: ItemListSectionId(self.section),
                style: .blocks(withTopInset: false, withExtendedBottomInset: false),
                editingNameUpdated: { editingName in arguments.updateEditingName(editingName) },
                avatarTapped: {},
                updatingImage: avatar,
                tag: CreateFolderEntryTag.info
            )
        case let .member(_, theme, strings, dateTimeFormat, peer, _):
            return ItemListPeerItem(
                theme: theme,
                strings: strings,
                dateTimeFormat: dateTimeFormat,
                nameDisplayOrder: .firstLast,
                account: arguments.account,
                peer: peer,
                presence: .none,
                text: .none,
                label: .none,
                editing: ItemListPeerItemEditing(
                    editable: false,
                    editing: false,
                    revealed: false
                ),
                switchValue: nil,
                enabled: true,
                selectable: false,
                sectionId: self.section,
                action: nil,
                setPeerIdWithRevealedOptions: { _, _ in },
                removePeer: { _ in }
            )
        }
    }
}

private struct CreateFolderState: Equatable {
    var creating: Bool
    var editingName: ItemListAvatarAndNameInfoItemName
    var avatar: ItemListAvatarAndNameInfoItemUpdatingAvatar?

    static func ==(lhs: CreateFolderState, rhs: CreateFolderState) -> Bool {
        if lhs.creating != rhs.creating {
            return false
        }
        if lhs.editingName != rhs.editingName {
            return false
        }
        if lhs.avatar != rhs.avatar {
            return false
        }

        return true
    }
}

private func createFolderEntries(presentationData: PresentationData, state: CreateFolderState, peerIds: [PeerId], view: MultiplePeersView) -> [CreateFolderEntry] {
    var entries: [CreateFolderEntry] = []
    
    let groupInfoState = ItemListAvatarAndNameInfoItemState(editingName: state.editingName, updatingName: nil)
    
    let peer = TelegramGroup(
        id: PeerId(namespace: -1, id: 0),
        title: state.editingName.composedTitle,
        photo: [],
        participantCount: 0,
        role: .creator(rank: nil),
        membership: .Member,
        flags: [],
        defaultBannedRights: nil,
        migrationReference: nil,
        creationDate: 0,
        version: 0
    )

    entries.append(.groupInfo(presentationData.theme, presentationData.strings, presentationData.dateTimeFormat, peer, groupInfoState, state.avatar))

    var peers: [Peer] = []
    for peerId in peerIds {
        if let peer = view.peers[peerId] {
            peers.append(peer)
        }
    }

    peers.sort(by: { lhs, rhs in
        let lhsPresence = view.presences[lhs.id] as? TelegramUserPresence
        let rhsPresence = view.presences[rhs.id] as? TelegramUserPresence
        if let lhsPresence = lhsPresence, let rhsPresence = rhsPresence {
            if lhsPresence.status < rhsPresence.status {
                return false
            } else if lhsPresence.status > rhsPresence.status {
                return true
            } else {
                return lhs.id < rhs.id
            }
        } else if let _ = lhsPresence {
            return true
        } else if let _ = rhsPresence {
            return false
        } else {
            return lhs.id < rhs.id
        }
    })

    for i in 0 ..< peers.count {
        entries.append(.member(Int32(i), presentationData.theme, presentationData.strings, presentationData.dateTimeFormat, peers[i], view.presences[peers[i].id]))
    }

    return entries
}

public func createFolderController(context: AccountContext, peerIds: [PeerId] = []) -> ViewController {
    let initialState = CreateFolderState(creating: false, editingName: .title(title: "", type: .folder), avatar: nil)
    let statePromise = ValuePromise(initialState, ignoreRepeated: true)
    let stateValue = Atomic(value: initialState)
    let updateState: ((CreateFolderState) -> CreateFolderState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }

    var dismissControllerImpl: (() -> Void)?
    var endEditingImpl: (() -> Void)?

    let actionsDisposable = DisposableSet()

    let arguments = CreateFolderArguments(account: context.account, updateEditingName: { editingName in
        guard case let .title(title, type) = editingName, type == .folder else { return }
        updateState { current in
            var current = current
            current.editingName = .title(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                type: .folder
            )
            return current
        }
    }, done: {
        let (creating, title) = stateValue.with { state -> (Bool, String) in
            return (state.creating, state.editingName.composedTitle.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        if !creating && !title.isEmpty {
            updateState { current in
                var current = current
                current.creating = true
                return current
            }
            endEditingImpl?()
            dismissControllerImpl?()
            actionsDisposable.add(
                (createFolder(account: context.account, title: title, peerIds: peerIds) |> deliverOnMainQueue).start()
            )
        }
    }, changeProfilePhoto: {
    })

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get(), context.account.postbox.multiplePeersView(peerIds))
        |> map { presentationData, state, view -> (ItemListControllerState, (ItemListNodeState<CreateFolderEntry>, CreateFolderEntry.ItemGenerationArguments)) in

            let rightNavigationButton: ItemListNavigationButton
            if state.creating {
                rightNavigationButton = ItemListNavigationButton(content: .none, style: .activity, enabled: true, action: {})
            } else {
                rightNavigationButton = ItemListNavigationButton(content: .text(presentationData.strings.Compose_Create), style: .bold, enabled: !state.editingName.composedTitle.isEmpty, action: {
                    arguments.done()
                })
            }

            let controllerState = ItemListControllerState(theme: presentationData.theme, title: .text(presentationData.strings.ComposeFolder_NewFolder), leftNavigationButton: nil, rightNavigationButton: rightNavigationButton, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
            let listState = ItemListNodeState(entries: createFolderEntries(presentationData: presentationData, state: state, peerIds: peerIds, view: view), style: .blocks, focusItemTag: CreateFolderEntryTag.info)

            return (controllerState, (listState, arguments))
        } |> afterDisposed {

            actionsDisposable.dispose()
    }

    let controller = ItemListController(context: context, state: signal)

    dismissControllerImpl = { [weak controller] in
        (controller?.navigationController as? NavigationController)?.popToRoot(animated: true)
    }
    controller.willDisappear = { _ in
        endEditingImpl?()
    }
    endEditingImpl = {
        [weak controller] in
        controller?.view.endEditing(true)
    }
    return controller
}

