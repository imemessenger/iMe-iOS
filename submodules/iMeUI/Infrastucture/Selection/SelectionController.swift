////
////  SelectionController.swift
////  TelegramUI
////
////  Created by Valeriy Mikholapov on 12/08/2019.
////  Copyright © 2019 Telegram. All rights reserved.
////
//
//import UIKit
//import SwiftSignalKit
//import AccountContext
//import TelegramPresentationData
//import iMeLib
//
//final class SelectionController<Item: TitledItem>: AiGramViewController<SelectionView> {
//
//    // MARK: - State
//
//    private let moduleContext: Context
//    private var state: State = .firstLoad {
//        didSet { typedView.set(viewModel: viewModel(for: state)) }
//    }
//
//    // MARK: - Lifecycle
//
//    init(
//        context: AccountContext,
//        moduleContext: Context
//    ) {
//        self.moduleContext = moduleContext
//        super.init(context: context)
//        setup(context: moduleContext)
//    }
//
//    required init(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    // MARK: - Customisation
//
//    private func viewModel(for state: State) -> ViewModel {
//        switch state {
//        case .firstLoad:
//            return .init()
//        case let .itemList(itemsInfo):
//            return .init(
//                cellModels: itemsInfo.items.map { .init(text: $0.title, isChecked: $0.id == itemsInfo.selected) },
//                cellSeleсtionCallback: cellTapped
//            )
//        }
//    }
//
//    private func setup(context: Context) {
//        let combinedItemsSignal = combineLatest(context.itemsSignal, context.selectedItemIdSignal)
//
//        disposables += (combinedItemsSignal |> deliverOnMainQueue)
//            .start(next: { [weak self] items, selectedId in
//                self?.state = State.itemList(.init(items: items, selected: selectedId))
//            })
//    }
//
//    override func title(_ strings: PresentationStrings) -> String {
//        return moduleContext.title
//    }
//
//    // MARK: - View callbacks
//
//    private lazy var cellTapped: (Int) -> Void = { [weak self] index in
//        if case let .itemList(itemsInfo)? = self?.state {
//            self?.moduleContext.itemSelectionCallback(itemsInfo.items[index])
//        }
//    }
//
//}
//
//// MARK: Inner types
//
//extension SelectionController {
//
//    typealias ViewModel = SelectionView.ViewModel
//    
//    struct ItemsInfo {
//        var items: [Item]
//        var selected: Item.Id
//    }
//
//    enum State {
//        case firstLoad
//        case itemList(ItemsInfo)
//    }
//
//    enum SelectionType {
//        case first
//        case itemIdSignal(Signal<Item.Id, NoError>)
//    }
//
//    struct Context {
//        let title: String
//        let itemsSignal: Signal<[Item], NoError>
//        let selectedItemIdSignal: Signal<Item.Id, NoError>
//        let itemSelectionCallback: (Item) -> Void
//    }
//}
