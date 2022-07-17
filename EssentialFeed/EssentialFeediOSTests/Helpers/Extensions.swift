//  Copyright © 2022 Andreas Link. All rights reserved.

import UIKit
import SwiftUI

extension UIEdgeInsets {
    static func horizontal(_ value: CGFloat) -> Self {
        .init(top: 0, left: value, bottom: 0, right: value)
    }

    static func vertical(_ value: CGFloat) -> Self {
        .init(top: value, left: 0, bottom: value, right: 0)
    }

    static func top(_ value: CGFloat) -> Self {
        .init(top: value, left: 0, bottom: 0, right: 0)
    }

    static func left(_ value: CGFloat) -> Self {
        .init(top: 0, left: value, bottom: 0, right: 0)
    }

    static func bottom(_ value: CGFloat) -> Self {
        .init(top: 0, left: 0, bottom: value, right: 0)
    }

    static func right(_ value: CGFloat) -> Self {
        .init(top: 0, left: 0, bottom: 0, right: value)
    }

    static func all(_ value: CGFloat) -> Self {
        .init(top: value, left: value, bottom: value, right: value)
    }
}

extension CGSize {
    func adding(_ insets: UIEdgeInsets) -> Self {
        CGSize(
            width: width + insets.left + insets.right,
            height: height + insets.top + insets.bottom
        )
    }
}

extension CGRect {
    init(width: CGFloat, height: CGFloat) {
        self.init(origin: .zero, size: CGSize(width: width, height: height))
    }

    static func size(_ value: CGSize) -> Self {
        self.init(origin: .zero, size: value)
    }

    static func size(width: CGFloat, height: CGFloat) -> Self {
        Self.size(CGSize(width: width, height: height))
    }
}

extension EdgeInsets {
    init(_ insets: UIEdgeInsets) {
        self.init(top: insets.top, leading: insets.left, bottom: insets.bottom, trailing: insets.right)
    }
}
