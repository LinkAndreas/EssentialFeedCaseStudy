//  Copyright © 2022 Andreas Link. All rights reserved.

import UIKit

extension UIView {
    func resolvedSize(for configuration: SnapshotConfiguration) -> CGSize {
        resolve(size: configuration.size)
            .adding(configuration.padding)
    }
}

extension UIView {
    private func resolve(size: CGSize) -> CGSize {
        switch (size.width, size.height) {
        case (UIView.layoutFittingCompressedSize.width, UIView.layoutFittingCompressedSize.height):
            return sizeThatFits(UIView.layoutFittingCompressedSize)

        case let (UIView.layoutFittingCompressedSize.width, height):
            return systemLayoutSizeFitting(
                CGSize(width: UIView.layoutFittingCompressedSize.width, height: height),
                withHorizontalFittingPriority: .defaultLow,
                verticalFittingPriority: .required
            )

        case let (width, UIView.layoutFittingCompressedSize.height):
            return systemLayoutSizeFitting(
                CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .defaultLow
            )

        case let (width, height):
            return CGSize(width: width, height: height)
        }
    }
}
