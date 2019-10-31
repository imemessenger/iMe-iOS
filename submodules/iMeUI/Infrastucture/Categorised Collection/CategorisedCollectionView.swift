//
//  CategorisedCollectionView.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 24/07/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit
import iMeLib
import TelegramPresentationData

protocol CategorisedViewModel {
    associatedtype CellModel: Equatable

    var sectionModels: [CategorisedCollectionSectionModel<CellModel>] { get }
    var itemSelectionCallback: (Int, Int) -> Void { get }
}

class CategorisedCollectionView<
    ViewModelType: CategorisedViewModel,
    CollectionManager: CategorisedCollectionManagerType
>: UIView, View, ThemeInitialisable where ViewModelType.CellModel == CollectionManager.CellModel {

    private lazy var collectionManager: CollectionManager = .init(tableView: tableView)

    // MARK: - Views

    private let tableView: UITableView = with(.init()) {
        $0.backgroundColor = .clear
    }

    // MARK: - Lifecycle

    required init(presentationData: PresentationData) {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(presentationData: PresentationData) {
        collectionManager.update(presentationData: presentationData)
        
        backgroundColor = presentationData.theme.iMe.backgroundColour
    }

    func set(viewModel: ViewModelType) {
        collectionManager.set(sectionModels: viewModel.sectionModels)
        collectionManager.set(itemSelectionCallback: viewModel.itemSelectionCallback)
    }

    // MARK: - Customisation

    private func setup() {
        setupHierarchy()
    }

    private func setupHierarchy() {
        with(tableView) {
            sv($0)
            layout(wire(view: $0))
        }
    }

}

