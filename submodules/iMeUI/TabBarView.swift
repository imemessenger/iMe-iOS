//
//  TabBarView.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 04/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit
import iMeLib
import TelegramPresentationData
import Display

public final class TabBarView: UIView {

    // MARK: - Constants

    public static let height: CGFloat = 44.0

    // MARK: -

    public var theme: PresentationTheme {
        didSet { apply(theme: theme) }
    }

    public var tapHandler: (TabItem) -> Void = { _ in }

    private let items: [TabItem] = []
    private var selectedItemInd: Int = 0

    // MARK: - Views

    private let stackView: UIStackView = with(.init()) {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
        $0.alignment = .fill
    }

    private let delimeterView: UIView = with(.init()) {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Lifecycle

    public init(theme: PresentationTheme) {
        self.theme = theme
        super.init(frame: .zero)
        setup()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -

    public func setMarks(for items: Set<TabItem>) {
        stackView.arrangedSubviews.forEach {
            guard let itemView = $0 as? TabItemView else { return }
            itemView.isMarked = items.contains(itemView.item)
        }
    }

    // MARK: - Appearance

    private func setup() {
        apply(theme: theme)

        with(delimeterView) {
            addSubview($0)
            NSLayoutConstraint.activate([
                leadingAnchor.constraint(equalTo: $0.leadingAnchor),
                trailingAnchor.constraint(equalTo: $0.trailingAnchor),
                bottomAnchor.constraint(equalTo: $0.bottomAnchor),
                $0.heightAnchor.constraint(equalToConstant: 0.5),
            ])
        }

        with(stackView) {
            addSubview($0)
            $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }

        for (ind, item) in TabItem.allCases.enumerated() {
            let itemView = TabItemView(item: item, theme: theme)
            itemView.isSelected = ind == selectedItemInd
            itemView.onTapAction = { [weak self] tabItem in
                guard let self = self else { return }
                let previouslySelectedItemView = self.stackView.arrangedSubviews[self.selectedItemInd] as? UIControl
                previouslySelectedItemView?.isSelected = false
                itemView.isSelected = true
                self.selectedItemInd = ind
                self.tapHandler(item)
            }

            stackView.addArrangedSubview(itemView)
        }
    }

    private func apply(theme: PresentationTheme) {
        backgroundColor = theme.chatList.backgroundColor
        delimeterView.backgroundColor = theme.chatList.itemSeparatorColor

        stackView.arrangedSubviews.forEach {
            ($0 as? TabItemView)?.theme = theme
        }
    }

}

