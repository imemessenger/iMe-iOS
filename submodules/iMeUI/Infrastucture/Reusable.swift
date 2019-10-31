//
//  Reusable.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 20/06/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit

// MARK: - Reusable

protocol Reusable: class {
    static var reuseIdentifier: String { get }
}

extension Reusable {
    static var reuseIdentifier: String {
        return .init(describing: self)
    }
}

extension UITableViewCell: Reusable { }

// MARK: - Colleciton view

extension UICollectionView {

    func register<T: UICollectionViewCell & Reusable>(_ type: T.Type) {
        register(type, forCellWithReuseIdentifier: T.reuseIdentifier)
    }

    func dequeueReusableCell<T: UICollectionViewCell & Reusable>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("The cell \(String(describing: T.self)) was not registered.")
        }
        return cell
    }

}

// MARK: - Table view

extension UITableView {

    func register<T: UITableViewCell>(_ type: T.Type) {
        register(type, forCellReuseIdentifier: T.reuseIdentifier)
    }

    func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("The cell \(String(describing: T.self)) was not registered.")
        }
        return cell
    }

    func dequeueReusableCell<T: UITableViewCell>(_ t: T.Type, for indexPath: IndexPath) -> T {
        return dequeueReusableCell(for: indexPath) as T
    }

}
