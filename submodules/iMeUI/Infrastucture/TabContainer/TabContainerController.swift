//
//  TabContainerController.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 18/07/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import iMeLib
import SwiftSignalKit
import Display
import TelegramPresentationData

public protocol ContainerTabItem: RawRepresentable, Hashable, CaseIterable where RawValue == Int {
    static var `default`: Self { get }
    func title(_ strings: PresentationStrings) -> String
}

public class TabContainerController<TabItem: ContainerTabItem>: AiGramViewController<TabContainerView<TabItem>> {

    // MARK: - State

    private var currentTab: TabItem = .default

    private var popGestureRecogniser: UIGestureRecognizer?

    var tabControllers: [TabItem: UIViewController] = [:]

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.switch(to: .default)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetPopGestureRecogniserIfNeeded(for: currentTab)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let view = navigationController?.view
        guard
            let popGestureRecogniser = popGestureRecogniser,
            view?.gestureRecognizers.map({ !$0.contains(popGestureRecogniser) }) ?? false
        else { return }
        view?.addGestureRecognizer(popGestureRecogniser)
    }

    func shouldAllowInteractivePopGesture(on tab: TabItem) -> Bool {
        return true
    }

    private func `switch`(to tab: TabItem) {
        let previousTab = currentTab
        currentTab = tab

        resetPopGestureRecogniserIfNeeded(for: currentTab)

        typedView.set(
            viewModel: .init(
                view: tabControllers[currentTab]?.view,
                tabItemSelected: { [weak self] in
                    guard self?.currentTab != $0 else { return }
                    self?.switch(to: $0)
                },
                viewWillAppear: carry(currentTab, willAppearClosure),
                viewDidAppear: carry(currentTab, didAppearClosure),
                viewWillDisappear: carry(previousTab, willDisappearClosure),
                viewDidDisappear: carry(previousTab, didDisappearClosure)
            )
        )
    }

    private func resetPopGestureRecogniserIfNeeded(for currentTab: TabItem) {
        let shouldUseInteractivePopGesture = shouldAllowInteractivePopGesture(on: currentTab)
        let usingInteractivePopGesture = popGestureRecogniser == nil

        switch (shouldUseInteractivePopGesture, usingInteractivePopGesture) {
            case (false, true):
                let view = navigationController?.viewIfLoaded
                guard let popGestureRecogniser = view?.gestureRecognizers?.first else { break }
                self.popGestureRecogniser = popGestureRecogniser
                view?.removeGestureRecognizer(popGestureRecogniser)
            case (true, false):
                guard let popGestureRecogniser = popGestureRecogniser else { break }
                navigationController?.viewIfLoaded?.addGestureRecognizer(popGestureRecogniser)
                self.popGestureRecogniser = nil
            default:
                break
        }
    }

    // MARK: -

    private lazy var willAppearClosure: (TabItem) -> Void = { [unowned self] in
        guard let vc = self.tabControllers[$0] else { return }
        vc.beginAppearanceTransition(true, animated: false)
        self.addChild(vc)
    }

    private lazy var didAppearClosure: (TabItem) -> Void = { [unowned self] in
        with(self.tabControllers[$0]) {
            $0?.endAppearanceTransition()
            $0?.didMove(toParent: self)
        }
    }

    private lazy var willDisappearClosure: (TabItem) -> Void = { [unowned self] in
        with(self.tabControllers[$0]) {
            $0?.beginAppearanceTransition(false, animated: false)
            $0?.willMove(toParent: nil)
            $0?.removeFromParent()
        }
    }

    private lazy var didDisappearClosure: (TabItem) -> Void = { [unowned self] in
        with(self.tabControllers[$0]) {
            $0?.removeFromParent()
            $0?.endAppearanceTransition()
        }
    }

}
