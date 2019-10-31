//
//  OverlayControllerNode.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 21/07/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Display
import AsyncDisplayKit
import iMeLib
import TelegramPresentationData

final class OverlayControllerNode: ASDisplayNode {

    // MARK: - Nodes

    private let dimmingNode: ASDisplayNode
    private let hintLabelNode: ASTextNode

    // MARK: -

    private var containerLayout: ContainerViewLayout?

    var dismiss: ((Bool) -> Void)?

    private let overlayMask: OverlayCircleMask

    private lazy var circleFrame: CGRect = .init(
        origin: overlayMask.origin,
        size: .init(width: overlayMask.radius * 2, height: overlayMask.radius * 2)
    )

    // MARK: - Lifecycle

    init(presentationData: PresentationData, overlayMask: OverlayCircleMask) {
        dimmingNode = ASDisplayNode()
        dimmingNode.backgroundColor = UIColor(white: 0.0, alpha: 0.6)

        hintLabelNode = .init()
        hintLabelNode.attributedText = NSAttributedString(
            string: presentationData.strings.ChannelCollection_Hint,
            font: Font.medium(20.0),
            textColor: .white,
            paragraphAlignment: .center
        )

        self.overlayMask = overlayMask

        super.init()

        addSubnode(dimmingNode)
        addSubnode(hintLabelNode)
    }

    override func didLoad() {
        super.didLoad()
        self.dimmingNode.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmingNodeTapGesture)))
    }

    func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        self.containerLayout = layout

        transition.updateFrame(node: self.dimmingNode, frame: CGRect(origin: CGPoint(), size: layout.size))

        let maxWidth = min(240.0, layout.size.width - 70.0)
        let hintLabelSize = hintLabelNode.measure(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        let hintLabelOrigin = CGPoint(
            x: layout.size.width / 2 - maxWidth / 2,
            y: layout.size.height / 2 - hintLabelSize.height / 2
        )

        let hintLabelFrame = CGRect(origin: hintLabelOrigin, size: hintLabelSize)

        transition.updateFrame(node: self.hintLabelNode, frame: hintLabelFrame)

        setupCircleMask(withOrigin: overlayMask.origin, radius: overlayMask.radius)
    }

    // MARK: - Animations

    func animateIn() {
        dimmingNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
        hintLabelNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.25)
        hintLabelNode.layer.animateSpring(
            from: 0.8 as NSNumber,
            to: 1.0 as NSNumber,
            keyPath: "transform.scale",
            duration: 0.5,
            initialVelocity: 0.0,
            removeOnCompletion: true,
            additive: false,
            completion: nil
        )
    }

    func animateOut(completion: @escaping () -> Void) {
        dimmingNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false)
        hintLabelNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false)
        hintLabelNode.layer.animateScale(from: 1.0, to: 0.8, duration: 0.4, removeOnCompletion: false) { _ in
            completion()
        }
    }

    // MARK: - Customisation

    private func setupCircleMask(withOrigin origin: CGPoint, radius: CGFloat) {
        let layer = dimmingNode.layer

        layer.mask = nil

        let layerFrame = CGRect(origin: .zero, size: layer.frame.size)

        let circlePath = CGPath(
            roundedRect: circleFrame,
            cornerWidth: radius,
            cornerHeight: radius,
            transform: nil
        )

        let maskPath = with(CGMutablePath()) {
            $0.addPath(CGPath(rect: layerFrame, transform: nil))
            $0.addPath(circlePath)
        }

        let maskLayer = with(CAShapeLayer()) {
            $0.fillColor = UIColor.white.cgColor
            $0.fillRule = .evenOdd
            $0.frame = layerFrame
            $0.path = maskPath
        }

        layer.mask = maskLayer
    }

    // MARK: - Actions

    @objc func dimmingNodeTapGesture(_ recognizer: UITapGestureRecognizer) {
        if case .ended = recognizer.state {
            let tapLocation = recognizer.location(in: dimmingNode.view)
            self.dismiss?(circleFrame.contains(tapLocation))
        }
    }

}

