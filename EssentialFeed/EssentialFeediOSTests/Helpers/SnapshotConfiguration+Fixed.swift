//  Copyright © 2022 Andreas Link. All rights reserved.

import UIKit

extension SnapshotConfiguration {
    static func fixed(
        width: Dimension,
        height: Dimension,
        style: UIUserInterfaceStyle,
        category: UIContentSizeCategory = .medium,
        padding: UIEdgeInsets = .zero,
        backgroundColor: UIColor = .systemBackground
    ) -> SnapshotConfiguration {
        SnapshotConfiguration(
            width: width,
            height: height,
            padding: padding,
            safeAreaInsets: .zero,
            layoutMargins: .zero,
            traitCollection: UITraitCollection(traitsFrom: [
                .init(forceTouchCapability: .unavailable),
                .init(layoutDirection: .leftToRight),
                .init(preferredContentSizeCategory: category),
                .init(userInterfaceIdiom: .unspecified),
                .init(horizontalSizeClass: .regular),
                .init(verticalSizeClass: .regular),
                .init(displayScale: UIScreen.main.scale),
                .init(displayGamut: .P3),
                .init(userInterfaceStyle: style)
            ]),
            backgroundColor: backgroundColor
        )
    }
}
