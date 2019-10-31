//
//  CategorisedCollectionManager.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 24/07/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit
import TelegramPresentationData

struct CategorisedCollectionSectionModel<CellModel: Equatable>: Equatable {
    let title: String
    let cellModels: [CellModel]
}

protocol CategorisedCollectionManagerType: Themable {
    associatedtype CellModel: Equatable

    init(tableView: UITableView)

    func set(sectionModels: [CategorisedCollectionSectionModel<CellModel>])
    func set(itemSelectionCallback: @escaping (Int, Int) -> Void)
}

class CategorisedCollectionManager<
    Cell: UICollectionViewCell & CategorisedCollectionCellType,
    Section: CategorisedCollectionSectionView<Cell>
>:
    NSObject,
    CategorisedCollectionManagerType,
    UITableViewDataSource,
    UITableViewDelegate
{

    // MARK: - State

    private var presentationData: PresentationData?

    private var offsets: [CGFloat] = []
    private var sectionModels: [CategorisedCollectionSectionModel<Cell.ViewModelType>] = [] {
        didSet {
            guard sectionModels != oldValue else { return }

            if offsets.count != sectionModels.count {
                offsets = .init(repeating: -16.0, count: sectionModels.count)
            }

            tableView.reloadData()
        }
    }

    // MARK: -

    private let tableView: UITableView
    private var itemSelectionCallback: ((Int, Int) -> Void)?

    // MARK: - Lifecycle

    required init(tableView: UITableView) {
        self.tableView = tableView

        super.init()

        tableView.register(Section.self)

        tableView.delegate = self
        tableView.dataSource = self

        tableView.backgroundColor = .clear

        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
    }

    func update(presentationData: PresentationData) {
        self.presentationData = presentationData
        tableView
            .visibleCells
            .compactMap { $0 as? Themable }
            .forEach { $0.update(presentationData: presentationData) }
    }

    func set(itemSelectionCallback: @escaping (Int, Int) -> Void) {
        self.itemSelectionCallback = itemSelectionCallback
    }

    func set(sectionModels: [CategorisedCollectionSectionModel<Cell.ViewModelType>]) {
        self.sectionModels = sectionModels
    }

    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as Section
        let model = sectionModels[indexPath.row]

        if let presentationData = presentationData {
            cell.update(presentationData: presentationData)
        }

        cell.set(collectionOffset: offsets[indexPath.row])

        cell.set(
            viewModel: .init(
                title: model.title,
                itemSelectionCallback: { [itemSelectionCallback] in
                    itemSelectionCallback?(indexPath.row, $0)
                },
                updateCollectionOffsetCallback: { [weak self] in
                    self?.offsets[indexPath.row] = $0
                },
                cellModels: model.cellModels
            )
        )

        return cell
    }

    // MARK: - Table view delegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 162
    }

}

