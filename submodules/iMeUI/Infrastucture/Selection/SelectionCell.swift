//
//  CountrySelectionCell.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 12/08/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit
import Display
import TelegramPresentationData
import iMeLib

final class SelectionCell: UITableViewCell, Themable {

    private let titleLabel: UILabel = with(.init()) {
        $0.font = Font.medium(16)
    }

    private let checkImageView: UIImageView = with(.init()) {
        $0.image = PresentationResourcesIME.checkMark()?.withRenderingMode(.alwaysTemplate)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(presentationData: PresentationData) {
        let theme = presentationData.theme.iMe

        titleLabel.textColor = theme.titleTextColour
        checkImageView.tintColor = theme.accentColour
    }

    func set(viewModel: ViewModel) {
        titleLabel.text = viewModel.text
        checkImageView.isHidden = !viewModel.isChecked
    }

    private func setup() {
        backgroundColor = .clear
        backgroundView?.backgroundColor = .clear
        contentView.backgroundColor = .clear

        setupHierarchy()
    }

    private func setupHierarchy() {
        with(checkImageView, titleLabel, self) {
            sv($0, $1)

            $0.horizontalHugging = .defaultHigh
            $1.horizontalCompressionResistance = .defaultLow

            layout(
                $0.layoutItem()
                    .wireRatio()
                    .wire(to: $2, by: \.trailingAnchor, insetedBy: -14)
                    .wire(to: $2, by: \.centerYAnchor),
                $1.layoutItem()
                    .wireVertically(to: $2)
                    .wire(to: $2, by: \.leadingAnchor, insetedBy: 14)
                    .wire(to: $0.leadingAnchor, by: \.trailingAnchor)
            )
        }
    }

}

extension SelectionCell {

    struct ViewModel {
        let text: String
        let isChecked: Bool
    }

}
