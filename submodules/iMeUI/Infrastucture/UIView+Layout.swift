//
//  UIView+Layout.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 20/06/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit
import iMeLib

extension CALayer {
    func addSublayers(_ sublayers: CALayer...) {
        sublayers.forEach(addSublayer)
    }
}

// MARK: - Layout

extension UIView {

    @discardableResult
    func sv(_ subviews: UIView...) -> UIView {
        subviews.forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        return self
    }

    func wire(
        to view: UIView,
        by anchorPath: KeyPath<UIView, NSLayoutXAxisAnchor>,
        insetedBy constant: CGFloat = 0.0
    ) -> NSLayoutConstraint {
        return self[keyPath: anchorPath].constraint(equalTo: view[keyPath: anchorPath], constant: constant)
    }

    func wire(
        to view: UIView,
        by anchorPath: KeyPath<UIView, NSLayoutYAxisAnchor>,
        insetedBy constant: CGFloat = 0.0
    ) -> NSLayoutConstraint {
        return self[keyPath: anchorPath].constraint(equalTo: view[keyPath: anchorPath], constant: constant)
    }

    func wire(
        to view: UIView,
        by anchorPath: KeyPath<UIView, NSLayoutDimension>,
        insetedBy constant: CGFloat = 0.0
    ) -> NSLayoutConstraint {
        return self[keyPath: anchorPath].constraint(equalTo: view[keyPath: anchorPath], constant: constant)
    }

    func wire(
        to anchor: NSLayoutXAxisAnchor,
        by anchorPath: KeyPath<UIView, NSLayoutXAxisAnchor>,
        insetedBy constant: CGFloat
    ) -> NSLayoutConstraint {
        return self[keyPath: anchorPath].constraint(equalTo: anchor, constant: constant)
    }

    func wire(
        to anchor: NSLayoutYAxisAnchor,
        by anchorPath: KeyPath<UIView, NSLayoutYAxisAnchor>,
        insetedBy constant: CGFloat = 0.0
    ) -> NSLayoutConstraint {
        return self[keyPath: anchorPath].constraint(equalTo: anchor, constant: constant)
    }

    func wire(
        to anchor: NSLayoutDimension,
        by anchorPath: KeyPath<UIView, NSLayoutDimension>,
        insetedBy constant: CGFloat = 0.0
    ) -> NSLayoutConstraint {
        return self[keyPath: anchorPath].constraint(equalTo: anchor, constant: constant)
    }

    func wireRatio() -> NSLayoutConstraint {
        return widthAnchor.constraint(equalTo: heightAnchor, multiplier: 1.0)
    }

    func wireHeight(to constant: CGFloat) -> NSLayoutConstraint {
        return heightAnchor.constraint(equalToConstant: constant)
    }

    func wireWidth(to constant: CGFloat) -> NSLayoutConstraint {
        return widthAnchor.constraint(equalToConstant: constant)
    }

    func wireHeight(to anchor: NSLayoutDimension) -> NSLayoutConstraint {
        return heightAnchor.constraint(equalTo: anchor)
    }

    func wireWidth(to anchor: NSLayoutDimension) -> NSLayoutConstraint {
        return widthAnchor.constraint(equalTo: anchor)
    }

    func wireSize(to view: UIView) -> [NSLayoutConstraint] {
        return [
            wireHeight(to: view.heightAnchor),
            wireWidth(to: view.widthAnchor)
        ]
    }

    func wireHorizontally(to view: UIView, insetedBy constant: CGFloat = 0.0) -> [NSLayoutConstraint] {
        return [\UIView.leadingAnchor, \.trailingAnchor].map {
            wire(to: view, by: $0, insetedBy: $0 == \.trailingAnchor ? -constant : constant)
        }
    }

    func wireVertically(to view: UIView, insetedBy constant: CGFloat = 0.0) -> [NSLayoutConstraint] {
        return [\UIView.topAnchor, \.bottomAnchor].map {
            wire(to: view, by: $0, insetedBy: $0 == \.bottomAnchor ? -constant : constant)
        }
    }

    func wireVertically(to view: UIView, topInset: CGFloat = 0.0, bottomInset: CGFloat = 0.0) -> [NSLayoutConstraint] {
        return [
            wire(to: view, by: \.topAnchor, insetedBy: topInset),
            wire(to: view, by: \.bottomAnchor, insetedBy: bottomInset)
        ]
    }

    func wireCentre(of view: UIView) -> [NSLayoutConstraint] {
        return [
            wire(to: view, by: \.centerYAnchor),
            wire(to: view, by: \.centerXAnchor)
        ]
    }

    func wire(view: UIView, insetedBy constant: CGFloat = 0.0) -> [NSLayoutConstraint] {
        return [wireHorizontally, wireVertically].flatMap { $0(view, -constant) }
    }

    func layout(_ constraints: [NSLayoutConstraint]...) {
        NSLayoutConstraint.activate(constraints.flatMap { $0 })
    }

}

// MARK: -

extension UIView {

    func _wire(
        to view: UIView,
        by anchorPath: KeyPath<UIView, NSLayoutXAxisAnchor>,
        insetedBy constant: CGFloat = 0.0
    ) -> LayoutItem {
        return .init(
            self,
            self[keyPath: anchorPath].constraint(equalTo: view[keyPath: anchorPath], constant: constant)
        )
    }

    func _wire(
        to view: UIView,
        by anchorPath: KeyPath<UIView, NSLayoutYAxisAnchor>,
        insetedBy constant: CGFloat = 0.0
    ) -> LayoutItem {
        return .init(
            self,
            self[keyPath: anchorPath].constraint(equalTo: view[keyPath: anchorPath], constant: constant)
        )
    }

    func _wire(
        to view: UIView,
        by anchorPath: KeyPath<UIView, NSLayoutDimension>,
        insetedBy constant: CGFloat = 0.0
    ) -> LayoutItem {
        return .init(
            self,
            self[keyPath: anchorPath].constraint(equalTo: view[keyPath: anchorPath], constant: constant)
        )
    }

    func _wire(
        to anchor: NSLayoutXAxisAnchor,
        by anchorPath: KeyPath<UIView, NSLayoutXAxisAnchor>,
        insetedBy constant: CGFloat = 0.0
    ) -> LayoutItem {
        return .init(
            self,
            self[keyPath: anchorPath].constraint(equalTo: anchor, constant: constant)
        )
    }

    func _wire(
        to anchor: NSLayoutYAxisAnchor,
        by anchorPath: KeyPath<UIView, NSLayoutYAxisAnchor>,
        insetedBy constant: CGFloat = 0.0
    ) -> LayoutItem {
        return .init(
            self,
            self[keyPath: anchorPath].constraint(equalTo: anchor, constant: constant)
        )
    }

    func _wire(
        to anchor: NSLayoutDimension,
        by anchorPath: KeyPath<UIView, NSLayoutDimension>,
        insetedBy constant: CGFloat = 0.0
    ) -> LayoutItem {
        return .init(
            self,
            self[keyPath: anchorPath].constraint(equalTo: anchor, constant: constant)
        )
    }

    func _wireRatio() -> LayoutItem {
        return .init(
            self,
            widthAnchor.constraint(equalTo: heightAnchor, multiplier: 1.0)
        )
    }

    func wire(height: CGFloat) -> LayoutItem {
        return .init(
            self,
            heightAnchor.constraint(equalToConstant: height)
        )
    }

    func wire(width: CGFloat) -> LayoutItem {
        return .init(
            self,
            widthAnchor.constraint(equalToConstant: width)
        )
    }

    func _wireHeight(to anchor: NSLayoutDimension) -> LayoutItem {
        return .init(
            self,
            heightAnchor.constraint(equalTo: anchor)
        )
    }

    func _wireWidth(to anchor: NSLayoutDimension) -> LayoutItem {
        return .init(
            self,
            widthAnchor.constraint(equalTo: anchor)
        )
    }

    func _wireSize(to view: UIView) -> LayoutItem {
        return .init(view, [
            wireHeight(to: view.heightAnchor),
            wireWidth(to: view.widthAnchor)
        ])
    }

    func _wireHorizontally(to view: UIView, insetedBy constant: CGFloat = 0.0) -> LayoutItem {
        return .init(view,
            [\UIView.leadingAnchor, \.trailingAnchor].map {
                wire(to: view, by: $0, insetedBy: $0 == \.trailingAnchor ? -constant : constant)
            }
        )
    }

    func _wireVertically(to view: UIView, insetedBy constant: CGFloat = 0.0) -> LayoutItem {
        return .init(
            view,
            [\UIView.topAnchor, \.bottomAnchor].map {
                wire(to: view, by: $0, insetedBy: $0 == \.bottomAnchor ? -constant : constant)
            }
        )
    }

    func _wireVertically(to view: UIView, topInset: CGFloat = 0.0, bottomInset: CGFloat = 0.0) -> LayoutItem {
        return .init(view, [
            wire(to: view, by: \.topAnchor, insetedBy: topInset),
            wire(to: view, by: \.bottomAnchor, insetedBy: bottomInset)
        ])
    }

    func _wireCentre(of view: UIView) -> LayoutItem {
        return .init(view, [
            wire(to: view, by: \.centerYAnchor),
            wire(to: view, by: \.centerXAnchor)
        ])
    }

    func _wire(view: UIView, insetedBy constant: CGFloat = 0.0) -> LayoutItem {
        return .init(
            self,
            [wireHorizontally, wireVertically].flatMap { $0(view, -constant) }
        )
    }

}

// MARK: - Layout Item

extension UIView {
    func layoutItem() -> LayoutItem {
        return .init(self, [])
    }

    func layout(_ layoutItems: LayoutItem...) {
        layout(layoutItems)
    }

    func layout(_ layoutItems: [[LayoutItem]]) {
        layout(layoutItems.flatten())
    }

    func layout(_ layoutItems: [LayoutItem]) {
        NSLayoutConstraint.activate(
            layoutItems.flatMap { $0.constraints }
        )
    }
}

final class LayoutItem {

    private let view: UIView

    fileprivate var constraints: [NSLayoutConstraint]

    fileprivate convenience init(_ view: UIView, _ constraint: NSLayoutConstraint) {
        self.init(view, [constraint])
    }

    fileprivate init(_ view: UIView, _ constraints: [NSLayoutConstraint]) {
        self.view = view
        self.constraints = constraints
    }

    @discardableResult
    func wire(
        to anotherView: UIView,
        by anchorPath: KeyPath<UIView, NSLayoutXAxisAnchor>,
        insetedBy constant: CGFloat = 0.0
    ) -> LayoutItem {
        constraints += view[keyPath: anchorPath].constraint(equalTo: anotherView[keyPath: anchorPath], constant: constant)
        return self
    }

    @discardableResult
    func wire(
        to anotherView: UIView,
        by anchorPath: KeyPath<UIView, NSLayoutYAxisAnchor>,
        insetedBy constant: CGFloat = 0.0
    ) -> LayoutItem {
        constraints += view[keyPath: anchorPath].constraint(equalTo: anotherView[keyPath: anchorPath], constant: constant)
        return self
    }

    @discardableResult
    func wire(
        to anotherView: UIView,
        by anchorPath: KeyPath<UIView, NSLayoutDimension>,
        insetedBy constant: CGFloat = 0.0
    ) -> LayoutItem {
        constraints += view[keyPath: anchorPath].constraint(equalTo: anotherView[keyPath: anchorPath], constant: constant)
        return self
    }

    @discardableResult
    func wire(
        to anchor: NSLayoutXAxisAnchor,
        by anchorPath: KeyPath<UIView, NSLayoutXAxisAnchor>,
        insetedBy constant: CGFloat = 0.0
    ) -> LayoutItem {
        constraints += view[keyPath: anchorPath].constraint(equalTo: anchor, constant: constant)
        return self
    }

    @discardableResult
    func wire(
        to anchor: NSLayoutYAxisAnchor,
        by anchorPath: KeyPath<UIView, NSLayoutYAxisAnchor>,
        insetedBy constant: CGFloat = 0.0
    ) -> LayoutItem {
        constraints += view[keyPath: anchorPath].constraint(equalTo: anchor, constant: constant)
        return self
    }

    @discardableResult
    func wire(
        to anchor: NSLayoutDimension,
        by anchorPath: KeyPath<UIView, NSLayoutDimension>,
        insetedBy constant: CGFloat = 0.0
    ) -> LayoutItem {
        constraints += view[keyPath: anchorPath].constraint(equalTo: anchor, constant: constant)
        return self
    }

    @discardableResult
    func wireRatio() -> LayoutItem {
        constraints += view.widthAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1.0)
        return self
    }

    @discardableResult
    func wire(height: CGFloat) -> LayoutItem {
        constraints += view.heightAnchor.constraint(equalToConstant: height)
        return self
    }

    @discardableResult
    func wire(width: CGFloat) -> LayoutItem {
        constraints += view.widthAnchor.constraint(equalToConstant: width)
        return self
    }

    @discardableResult
    func wireHeight(to anchor: NSLayoutDimension) -> LayoutItem {
        constraints += view.heightAnchor.constraint(equalTo: anchor)
        return self
    }

    @discardableResult
    func wireWidth(to anchor: NSLayoutDimension) -> LayoutItem {
        constraints += view.widthAnchor.constraint(equalTo: anchor)
        return self
    }

    @discardableResult
    func wireSize(to view: UIView) -> LayoutItem {
        wireHeight(to: view.heightAnchor)
        wireWidth(to: view.widthAnchor)
        return self
    }

    @discardableResult
    func wireHorizontally(to view: UIView, insetedBy constant: CGFloat = 0.0) -> LayoutItem {
        [\UIView.leadingAnchor, \.trailingAnchor].forEach {
            wire(to: view, by: $0, insetedBy: $0 == \.trailingAnchor ? -constant : constant)
        }
        return self
    }

    @discardableResult
    func wireVertically(to view: UIView, insetedBy constant: CGFloat = 0.0) -> LayoutItem {
        [\UIView.topAnchor, \.bottomAnchor].forEach {
            wire(to: view, by: $0, insetedBy: $0 == \.bottomAnchor ? -constant : constant)
        }
        return self
    }

    @discardableResult
    func wireVertically(to view: UIView, topInset: CGFloat = 0.0, bottomInset: CGFloat = 0.0) -> LayoutItem {
        wire(to: view, by: \.topAnchor, insetedBy: topInset)
        wire(to: view, by: \.bottomAnchor, insetedBy: bottomInset)
        return self
    }

    @discardableResult
    func wireCentre(of view: UIView) -> LayoutItem {
        wire(to: view, by: \.centerYAnchor)
        wire(to: view, by: \.centerXAnchor)
        return self
    }

    @discardableResult
    func wire(view: UIView, insetedBy constant: CGFloat = 0.0) -> LayoutItem {
        [wireHorizontally, wireVertically].forEach { _ = $0(view, -constant) }
        return self
    }

}

// MARK: - Layout priorities

extension UIView {

    func set(hugging: UILayoutPriority) {
        verticalHugging = hugging
        horizontalHugging = hugging
    }

    var verticalHugging: UILayoutPriority {
        get { return contentHuggingPriority(for: .vertical) }
        set { setContentHuggingPriority(newValue, for: .vertical) }
    }

    var horizontalHugging: UILayoutPriority {
        get { return contentHuggingPriority(for: .horizontal) }
        set { setContentHuggingPriority(newValue, for: .horizontal) }
    }

    func set(compressionResistance: UILayoutPriority) {
        verticalCompressionResistance = compressionResistance
        horizontalCompressionResistance = compressionResistance
    }

    var verticalCompressionResistance: UILayoutPriority {
        get { return contentCompressionResistancePriority(for: .vertical) }
        set { setContentCompressionResistancePriority(newValue, for: .vertical) }
    }

    var horizontalCompressionResistance: UILayoutPriority {
        get { return contentCompressionResistancePriority(for: .horizontal) }
        set { setContentCompressionResistancePriority(newValue, for: .horizontal) }
    }

}
