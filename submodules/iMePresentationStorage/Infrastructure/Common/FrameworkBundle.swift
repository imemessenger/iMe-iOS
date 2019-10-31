//
//  FrameworkBundle.swift
//  iMeUI
//
//  Created by Oleksandr Shynkarenko on 9/16/19.
//  Copyright © 2019 Valeriy Mikholapov. All rights reserved.
//

import UIKit

private class FrameworkBundleClass: NSObject {
}

let frameworkBundle: Bundle = Bundle(for: FrameworkBundleClass.self)

public extension UIImage {
    convenience init?(bundleImageName: String) {
        self.init(named: bundleImageName, in: frameworkBundle, compatibleWith: nil)
    }
}
