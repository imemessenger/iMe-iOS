//
//  CountrySelectionTableManager.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 12/08/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit
import TelegramPresentationData
import iMeLib

final class SelectionTableManager: NSObject {

    private let tableView: UITableView
    private var presentationData: PresentationData

    private var cellModels: [CellModel] = [] {
        didSet { tableView.reloadData() }
    }

    private var cellSelectionCallback: ((Int) -> Void)?

    init(tableView: UITableView, presentationData: PresentationData) {
        self.tableView = tableView
        self.presentationData = presentationData

        super.init()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SelectionCell.self)
    }

    func set(cellModels: [CellModel], cellSelectionCallback: ((Int) -> Void)?) {
        self.cellModels = cellModels
        self.cellSelectionCallback = cellSelectionCallback
    }

    func update(presentationData: PresentationData) {
        self.presentationData = presentationData
    }

}

// MARK: - Table delegate

extension SelectionTableManager: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
        cellSelectionCallback?(indexPath.row)
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.setSelected(false, animated: false)
    }

}

// MARK: - Table data source

extension SelectionTableManager: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return with(tableView.dequeueReusableCell(SelectionCell.self, for: indexPath)) {
            $0.update(presentationData: presentationData)
            $0.set(viewModel: cellModels[indexPath.row])
        }
    }

}

// MARK: - Inner types

extension SelectionTableManager {

    typealias CellModel = SelectionCell.ViewModel

}
