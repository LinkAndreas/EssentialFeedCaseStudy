//  Copyright © 2022 Andreas Link. All rights reserved.

import UIKit

extension UIView {
    func resolvedSize(for configuration: SnapshotConfiguration) -> CGSize {
        resolve(width: configuration.width, height: configuration.height)
            .adding(configuration.padding)
    }
}

extension UIView {
    private func resolve(width: Dimension, height: Dimension) -> CGSize {
        switch (width, height) {
        case (.compressed, .compressed):
            return sizeThatFits(UIView.layoutFittingCompressedSize)

        case let (.compressed, .value(height)):
            return systemLayoutSizeFitting(
                CGSize(width: UIView.layoutFittingCompressedSize.width, height: height),
                withHorizontalFittingPriority: .defaultLow,
                verticalFittingPriority: .required
            )

        case let (.value(width), .compressed):
            return systemLayoutSizeFitting(
                CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .defaultLow
            )

        case let (.value(width), .value(height)):
            return CGSize(width: width, height: height)
        }
    }
}
