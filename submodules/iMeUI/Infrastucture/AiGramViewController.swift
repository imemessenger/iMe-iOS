//
//  AiGramViewController.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 20/06/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit
import SwiftSignalKit
import Display
import TelegramPresentationData
import SearchUI
import AccountContext
import iMeLib

public protocol EmptyInitialisable {
    init()
}

public protocol View: class {
    associatedtype ViewModelType
    func set(viewModel: ViewModelType)
}

public protocol ThemeInitialisable: Themable {
    init(presentationData: PresentationData)
}

public protocol Themable: class {
    func update(presentationData: PresentationData)
}

public class AiGramViewController<V: UIView & View & ThemeInitialisable>: ViewController where V.ViewModelType: EmptyInitialisable {

    lazy var typedView: V = .init(presentationData: presentationData)

    private let searchContentNode: NavigationBarSearchContentNode

    var disposables: [Disposable] = []

    let context: AccountContext
    var presentationData: PresentationData

    public init(context: AccountContext) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.searchContentNode = .init(
            theme: presentationData.theme,
            placeholder: presentationData.strings.Common_Search,
            activate: {
                print("Search activated")
            }
        )

        super.init(navigationBarPresentationData: .init(presentationData: presentationData))

        disposables += (context.sharedContext.presentationData
            |> deliverOnMainQueue)
            .start(next: { [weak self, presentationData] in
                let previousTheme = presentationData.theme
                let previousStrings = presentationData.strings

                self?.presentationData = $0

                if previousTheme !== $0.theme || previousStrings !== $0.strings {
                    self?.updateThemeAndStrings()
                }
            })

        navigationBar?.setContentNode(searchContentNode, animated: false)

        updateThemeAndStrings()
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        disposables.forEach { $0.dispose() }
    }

    override public func loadView() {
        super.loadView()
        view.addSubview(typedView)
        viewDidLoad()
    }

    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)

        searchContentNode.updateExpansionProgress(0.0)

        typedView.frame.origin = CGPoint(x: 0, y: navigationHeight)
        typedView.frame.size = CGSize(width: view.bounds.width, height: view.bounds.height - navigationHeight)
    }

    override public func loadDisplayNode() {
        displayNode = ViewControllerTracingNode()
        displayNodeDidLoad()
    }

    func updateThemeAndStrings() {
        navigationBar?.updatePresentationData(.init(presentationData: presentationData))
        statusBar.statusBarStyle = presentationData.theme.rootController.statusBarStyle.style

        typedView.update(presentationData: presentationData)

        navigationItem.title = title(presentationData.strings)
        navigationItem.backBarButtonItem = .init(
            title: presentationData.strings.Common_Back,
            style: .plain,
            target: nil,
            action: nil
        )
    }

    func title(_ strings: PresentationStrings) -> String {
        assertionFailure("Subclasses must implement this method!")
        return ""
    }

}

class PlainController<V: UIView & View & ThemeInitialisable>: UIViewController where V.ViewModelType: EmptyInitialisable {

    lazy var typedView: V = .init(presentationData: presentationData)

    let context: AccountContext
    var presentationData: PresentationData

    var disposables: [Disposable] = []

    init(context: AccountContext) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }

        super.init(nibName: nil, bundle: nil)

        disposables += (context.sharedContext.presentationData
            |> deliverOnMainQueue)
            .start(next: { [weak self, presentationData] in
                let previousTheme = presentationData.theme
                let previousStrings = presentationData.strings

                self?.presentationData = $0

                if previousTheme !== $0.theme || previousStrings !== $0.strings {
                    self?.updateThemeAndStrings()
                }
            })

        updateThemeAndStrings()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        disposables.forEach { $0.dispose() }
    }

    override func loadView() {
        view = typedView
        typedView.set(viewModel: .init())
    }

    func updateThemeAndStrings() {
        typedView.update(presentationData: presentationData)
    }
}
