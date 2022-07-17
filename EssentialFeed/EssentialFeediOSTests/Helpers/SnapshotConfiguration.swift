//  Copyright © 2022 Andreas Link. All rights reserved.

import UIKit

struct SnapshotConfiguration {
    let size: CGSize
    let padding: UIEdgeInsets
    let safeAreaInsets: UIEdgeInsets
    let layoutMargins: UIEdgeInsets
    let traitCollection: UITraitCollection
    let backgroundColor: UIColor

    init(
        size: CGSize,
        padding: UIEdgeInsets = .zero,
        safeAreaInsets: UIEdgeInsets = .zero,
        layoutMargins: UIEdgeInsets = .zero,
        traitCollection: UITraitCollection,
        backgroundColor: UIColor = .systemBackground
    ) {
        self.size = size
        self.padding = padding
        self.safeAreaInsets = safeAreaInsets
        self.layoutMargins = layoutMargins
        self.traitCollection = traitCollection
        self.backgroundColor = backgroundColor
    }
}
