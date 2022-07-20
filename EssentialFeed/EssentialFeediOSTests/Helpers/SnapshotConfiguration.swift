//  Copyright © 2022 Andreas Link. All rights reserved.

import UIKit

struct SnapshotConfiguration {
    let width: Dimension
    let height: Dimension
    let padding: UIEdgeInsets
    let safeAreaInsets: UIEdgeInsets
    let layoutMargins: UIEdgeInsets
    let traitCollection: UITraitCollection
    let backgroundColor: UIColor

    init(
        width: Dimension,
        height: Dimension,
        padding: UIEdgeInsets = .zero,
        safeAreaInsets: UIEdgeInsets = .zero,
        layoutMargins: UIEdgeInsets = .zero,
        traitCollection: UITraitCollection,
        backgroundColor: UIColor = .systemBackground
    ) {
        self.width = width
        self.height = height
        self.padding = padding
        self.safeAreaInsets = safeAreaInsets
        self.layoutMargins = layoutMargins
        self.traitCollection = traitCollection
        self.backgroundColor = backgroundColor
    }
}
