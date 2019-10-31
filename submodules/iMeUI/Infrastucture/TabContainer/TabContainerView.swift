//
//  TabContainerView.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 18/07/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit
import TelegramPresentationData
import iMeLib

public final class TabContainerView<TabItem: ContainerTabItem>: UIView, View, ThemeInitialisable {

    // MARK: - State

    var presentationData: PresentationData

    private var segmentTitles: [String] {
        return TabItem.allCases
            .map { $0.title(presentationData.strings) }
    }

    private var tabItemSelected: ((TabItem) -> Void)?

    // MARK: - Views

    private lazy var segmentedControl: UISegmentedControl = with(
        .init(items: segmentTitles)
    ) {
        $0.selectedSegmentIndex = 0
    }

    private let container: UIView = .init()

    // MARK: - Lifecycle

    public init(presentationData: PresentationData) {
        self.presentationData = presentationData
        super.init(frame: .zero)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(viewModel: ViewModel) {
        tabItemSelected = viewModel.tabItemSelected
        guard let view = viewModel.view else { return }

        if !container.subviews.isEmpty {
            viewModel.viewWillDisappear?()
            container.subviews.forEach { $0.removeFromSuperview() }
            viewModel.viewDidDisappear?()
        }

        viewModel.viewWillAppear?()
        
        wrap(view, container) {
            $1.sv($0)
            $1.layout(
                $1.wire(view: $0)
            )
        }

        viewModel.viewDidAppear?()
    }

    public func update(presentationData: PresentationData) {
        self.presentationData = presentationData

        segmentTitles
            .enumerated()
            .forEach { segmentedControl.setTitle($1, forSegmentAt: $0) }

        let theme = presentationData.theme.iMe
        segmentedControl.tintColor = theme.accentColour
        backgroundColor = theme.backgroundColour
    }

    // MARK: - Customisation

    private func setup() {
        setupHierarchy()
        update(presentationData: presentationData)

        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
    }

    private func setupHierarchy() {
        sv(segmentedControl, container)

        layout(
            wrapFlat(segmentedControl, self) {[
                $0.wireHorizontally(to: $1, insetedBy: 16),
                [$0.wire(to: $1, by: \.topAnchor, insetedBy: 15),
                 $0.wireHeight(to: 27)]
            ]},
            wrapFlat(container, segmentedControl, self) {[
                $0.wireHorizontally(to: $2),
                [$0.topAnchor.constraint(equalTo: $1.bottomAnchor, constant: 15),
                 $0.wire(to: $2, by: \.bottomAnchor)]
            ]}
        )
    }

    // MARK: - Actions

    @objc
    private func segmentedControlValueChanged() {
        guard let tab = TabItem(rawValue: segmentedControl.selectedSegmentIndex) else {
            return assertionFailure("Unrecognised tab index.")
        }
        tabItemSelected?(tab)
    }

}

// MARK: - Inner Types

extension TabContainerView {

    public struct ViewModel: EmptyInitialisable {
        let view: UIView?

        let tabItemSelected: ((TabItem) -> Void)?

        let viewWillAppear: (() -> Void)?
        let viewDidAppear: (() -> Void)?
        let viewWillDisappear: (() -> Void)?
        let viewDidDisappear: (() -> Void)?

        public init() {
            self.init(view: nil)
        }

        init(
            view: UIView? = nil,
            tabItemSelected: ((TabItem) -> Void)? = nil,
            viewWillAppear:  (() -> Void)? = nil,
            viewDidAppear: (() -> Void)? = nil,
            viewWillDisappear: (() -> Void)? = nil,
            viewDidDisappear: (() -> Void)? = nil
        ) {
            self.view = view
            self.tabItemSelected = tabItemSelected
            self.viewWillAppear = viewWillAppear
            self.viewDidAppear = viewDidAppear
            self.viewWillDisappear = viewWillDisappear
            self.viewDidDisappear = viewDidDisappear
        }
    }

}


