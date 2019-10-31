//
//  CountrySelectionView.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 12/08/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit
import Display
import TelegramPresentationData
import iMeLib

final class SelectionView: UIView, View, ThemeInitialisable {

    private var presentationData: PresentationData
    private lazy var tableManager: SelectionTableManager = .init(tableView: tableView, presentationData: presentationData)

    // MARK: - Views

    private let tableView: UITableView = with(.init()) {
        $0.separatorInset = .zero
        $0.tableFooterView = .init()
        $0.backgroundColor = .clear
    }

    // MARK: - Lifecycle

    init(presentationData: PresentationData) {
        self.presentationData = presentationData
        super.init(frame: .zero)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Customisation

    func update(presentationData: PresentationData) {
        self.presentationData = presentationData
        backgroundColor = presentationData.theme.iMe.backgroundColour
    }


    func set(viewModel: ViewModel) {
        tableManager.set(cellModels: viewModel.cellModels, cellSelectionCallback: viewModel.cellSeleсtionCallback)
    }

    private func setup() {
        _ = tableManager
        setupHierarchy()
    }

    private func setupHierarchy() {
        with(tableView) {
            sv($0)
            layout(
                layoutItem().wire(view: $0)
            )
        }
    }

}

extension SelectionView {

    struct ViewModel: EmptyInitialisable {
        let cellModels: [SelectionCell.ViewModel]
        let cellSeleсtionCallback: ((Int) -> Void)?

        init() {
            self.init(cellModels: [])
        }

        init(
            cellModels: [SelectionCell.ViewModel] = [],
            cellSeleсtionCallback: ((Int) -> Void)? = nil
        ) {
            self.cellModels = cellModels
            self.cellSeleсtionCallback = cellSeleсtionCallback
        }

    }

}
