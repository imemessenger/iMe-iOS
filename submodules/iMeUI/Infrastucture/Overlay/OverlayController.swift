//
//  OverlayController.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 21/07/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit
import Display
import TelegramPresentationData

public struct OverlayCircleMask {
    let origin: CGPoint
    let radius: CGFloat
    
    public init(origin: CGPoint, radius: CGFloat) {
        self.origin = origin
        self.radius = radius
    }
}

public final class OverlayController: ViewController {

    private var controllerNode: OverlayControllerNode {
        return self.displayNode as! OverlayControllerNode
    }

    var dismissed: (() -> Void)?

    /// Called after dismiss transition is finished and
    /// only if the user tapped on masked area.
    private let buttonTapHandler: () -> Void

    // MARK: - State

    private let presentationData: PresentationData
    private let overlayMask: OverlayCircleMask

    // MARK: - Lifecycle

    public init(presentationData: PresentationData, overlayMask: OverlayCircleMask, buttonTapHandler: @escaping () -> Void) {
        self.presentationData = presentationData
        self.overlayMask = overlayMask
        self.buttonTapHandler = buttonTapHandler

        super.init(navigationBarPresentationData: nil)

        self.blocksBackgroundWhenInOverlay = true

        self.statusBar.statusBarStyle = .Ignore
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadDisplayNode() {
        self.displayNode = OverlayControllerNode(presentationData: presentationData, overlayMask: overlayMask)
        self.displayNodeDidLoad()

        self.controllerNode.dismiss = { [weak self] isInMaskedArea in
            if let strongSelf = self {
                strongSelf.controllerNode.animateOut {
                    self?.dismiss()
                    if isInMaskedArea {
                        self?.buttonTapHandler()
                    }
                }
            }
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.controllerNode.animateIn()
    }

    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.controllerNode.containerLayoutUpdated(layout, transition: transition)
    }

    override public func dismiss(completion: (() -> Void)? = nil) {
        self.dismissed?()
        self.presentingViewController?.dismiss(animated: false, completion: completion)
    }

}
