//
//  CategorisedCollectionCell.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 24/07/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit
import Display
import iMeLib
import TelegramPresentationData

protocol CategorisedCollectionCellType: Reusable, Themable {
    associatedtype ViewModelType: CategorisedCollectionCellViewModel
    func set(viewModel: ViewModelType)
}

protocol CategorisedCollectionCellViewModel: Equatable {
    var imageUrl: URL? { get }
    var title: String { get }
}

class CategorisedCollectionCell<ViewModelType: CategorisedCollectionCellViewModel>:
    UICollectionViewCell,
    CategorisedCollectionCellType,
    Themable
{

    // MARK: - Views

    let imageView: UIImageView = with(.init()) {
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = .clear
    }

    let titleLabel: UILabel = with(.init()) {
        $0.font = Font.medium(12)
    }

    let subtitleView: UIView = .init()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(presentationData: PresentationData) {
        let theme = presentationData.theme.iMe
        imageView.backgroundColor = theme.imageBackgroundColour
        titleLabel.textColor = theme.titleTextColour
    }

    func set(viewModel: ViewModelType) {
        imageView.setImage(fromUrl: viewModel.imageUrl)
        titleLabel.text = viewModel.title
    }

    // MARK: - Customisation

    func setup() {
        backgroundView?.backgroundColor = .clear
        contentView.backgroundColor = .clear

        setupHierarchy()
    }

    func setupHierarchy() {
        contentView.sv(
            imageView,
            titleLabel,
            subtitleView
        )

        titleLabel.verticalCompressionResistance = .init(rawValue: 999)
        titleLabel.verticalHugging = .init(rawValue: 999)

        layout(
            wrapFlat(imageView, contentView) {[
                $0.wireHorizontally(to: $1),
                [$0.wire(to: $1, by: \.topAnchor),
                 $0.wireRatio()]
                ]},
            wrapFlat(titleLabel, imageView, contentView) {[
                $0.wireHorizontally(to: $2),
                [$0.topAnchor.constraint(equalTo: $1.bottomAnchor, constant: 6)]
                ]},
            wrapFlat(subtitleView, titleLabel, contentView) {[
                $0.wireHorizontally(to: $2),
                [$0.wire(to: $2, by: \.bottomAnchor),
                 $0.wire(to: $1.bottomAnchor, by: \.topAnchor)]
                ]},
            layoutSubtitleView()
        )
    }

    func layoutSubtitleView() -> [NSLayoutConstraint] {
        return []
    }

}

