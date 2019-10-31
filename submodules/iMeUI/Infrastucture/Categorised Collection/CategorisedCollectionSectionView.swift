//
//  CategorisedCollectionSectionView.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 24/07/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit
import Display
import TelegramPresentationData
import iMeLib

class CategorisedCollectionSectionView<Cell: UICollectionViewCell & CategorisedCollectionCellType>:
    UITableViewCell,
    Themable,
    UICollectionViewDelegateFlowLayout,
    UICollectionViewDataSource
{

    struct ViewModel {
        let title: String
        let itemSelectionCallback: ((Int) -> Void)?
        let updateCollectionOffsetCallback: ((CGFloat) -> Void)?
        let cellModels: [Cell.ViewModelType]
    }

    // MARK: - State

    private var presentationData: PresentationData?
    private var cellModels: [Cell.ViewModelType] = []

    var collectionViewHeight: CGFloat { return 117.0 }

    // MARK: - Views

    private let titleLabel: UILabel = with(.init()) {
        $0.font = Font.medium(16)
    }

    private lazy var collectionView: UICollectionView = with(
        .init(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    ) {
        $0.backgroundColor = .clear
        $0.contentInset = .insets(horizontal: 16)

        $0.showsVerticalScrollIndicator = false
        $0.showsHorizontalScrollIndicator = false
        $0.isDirectionalLockEnabled = true

        ($0.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .horizontal

        $0.delegate = self
        $0.dataSource = self

        $0.register(Cell.self)
    }

    // MARK: - Callbacks

    private var itemSelectionCallback: ((Int) -> Void)?
    private var updateCollectionOffsetCallback: ((CGFloat) -> Void)?

    // MARK: - Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        updateCollectionOffsetCallback = nil
    }

    func set(collectionOffset: CGFloat) {
        collectionView.setContentOffset(.init(x: collectionOffset, y: collectionView.contentOffset.y), animated: false)
    }

    func set(viewModel: ViewModel) {
        titleLabel.text = viewModel.title
        itemSelectionCallback = viewModel.itemSelectionCallback
        updateCollectionOffsetCallback = viewModel.updateCollectionOffsetCallback
        if cellModels != viewModel.cellModels {
            cellModels = viewModel.cellModels
            collectionView.reloadData()
        }
    }

    func update(presentationData: PresentationData) {
        self.presentationData = presentationData

        collectionView.visibleCells.forEach {
            ($0 as? Themable)?.update(presentationData: presentationData)
        }
        
        titleLabel.textColor = presentationData.theme.iMe.titleTextColour
    }

    // MARK: - Customisation

    func setup() {
        backgroundView?.backgroundColor = .clear
        contentView.backgroundColor = .clear
        backgroundColor = .clear

        selectionStyle = .none

        setupHierarchy()
    }

    func setupHierarchy() {
        contentView.sv(titleLabel, collectionView)

        titleLabel.setContentCompressionResistancePriority(.init(rawValue: 999), for: .vertical)

        layout(
            wrapFlat(titleLabel, collectionView, contentView) {[
                $0.wireHorizontally(to: $2, insetedBy: 16),
                $1.wireHorizontally(to: $2),
                [$0.wire(to: $2, by: \.topAnchor),
                 $1.wireHeight(to: collectionViewHeight),
                 $1.wire(to: $0.bottomAnchor, by: \.topAnchor, insetedBy: 12)]
            ]}
        )
    }

    // MARK: - Collection view data source

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellModels.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as Cell
        let model = cellModels[indexPath.item]

        if let presentationData = presentationData {
            cell.update(presentationData: presentationData)
        }

        cell.set(viewModel: model)

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        itemSelectionCallback?(indexPath.item)
    }

    // MARK: - Collection view delegate

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return .init(width: 80, height: 117)
    }

    // MARK: - Scroll view delegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCollectionOffsetCallback?(scrollView.contentOffset.x)
    }

}

