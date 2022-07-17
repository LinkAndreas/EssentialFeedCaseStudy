//  Copyright © 2022 Andreas Link. All rights reserved.

import UIKit

extension SnapshotConfiguration {
    static func fixed(
        width: CGFloat,
        height: CGFloat,
        style: UIUserInterfaceStyle,
        category: UIContentSizeCategory = .medium,
        padding: UIEdgeInsets = .zero,
        backgroundColor: UIColor = .systemBackground
    ) -> SnapshotConfiguration {
        fixed(
            size: CGSize(width: width, height: height),
            style: style,
            category: category,
            padding: padding,
            backgroundColor: backgroundColor
        )
    }

    static func fixed(
        size: CGSize,
        style: UIUserInterfaceStyle,
        category: UIContentSizeCategory = .medium,
        padding: UIEdgeInsets = .zero,
        backgroundColor: UIColor = .systemBackground
    ) -> SnapshotConfiguration {
        SnapshotConfiguration(
            size: size,
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
