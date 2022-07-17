//  Copyright © 2022 Andreas Link. All rights reserved.

import UIKit

extension SnapshotConfiguration {
    static func compressed(
        style: UIUserInterfaceStyle,
        category: UIContentSizeCategory = .medium,
        padding: UIEdgeInsets = .zero,
        backgroundColor: UIColor = .systemBackground
    ) -> SnapshotConfiguration {
        fixed(
            size: UIView.layoutFittingCompressedSize,
            style: style,
            category: category,
            padding: padding,
            backgroundColor: backgroundColor
        )
    }
}
