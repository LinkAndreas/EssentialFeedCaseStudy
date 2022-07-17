//  Copyright © 2022 Andreas Link. All rights reserved.

import UIKit

extension SnapshotConfiguration {
    static func iPhone8(
        style: UIUserInterfaceStyle,
        category: UIContentSizeCategory = .medium
    ) -> SnapshotConfiguration {
        SnapshotConfiguration(
            size: CGSize(width: 375, height: 667),
            padding: .zero,
            safeAreaInsets: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0),
            layoutMargins: UIEdgeInsets(top: 20, left: 16, bottom: 0, right: 16),
            traitCollection: UITraitCollection(traitsFrom: [
                .init(forceTouchCapability: .available),
                .init(layoutDirection: .leftToRight),
                .init(preferredContentSizeCategory: category),
                .init(userInterfaceIdiom: .phone),
                .init(horizontalSizeClass: .compact),
                .init(verticalSizeClass: .regular),
                .init(displayScale: 2),
                .init(displayGamut: .P3),
                .init(userInterfaceStyle: style)
            ])
        )
    }
}
