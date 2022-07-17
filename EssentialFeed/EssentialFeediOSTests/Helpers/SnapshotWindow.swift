//  Copyright © 2022 Andreas Link. All rights reserved.

import UIKit

final class SnapshotWindow: UIWindow {
    private var configuration: SnapshotConfiguration = .iPhone8(style: .light)

    convenience init(configuration: SnapshotConfiguration, root: UIViewController) {
        self.init(frame: root.view.bounds)
        self.configuration = configuration
        self.layoutMargins = configuration.layoutMargins

        rootViewController = root
        isHidden = false
    }

    override var safeAreaInsets: UIEdgeInsets {
        configuration.safeAreaInsets
    }

    override var traitCollection: UITraitCollection {
        configuration.traitCollection
    }

    func snapshot() -> UIImage {
        guard let root = rootViewController else { return UIImage() }
        let resolvedSize = root.view.resolvedSize(for: configuration)
        bounds.size = resolvedSize

        return UIGraphicsImageRenderer(
            bounds: .init(origin: .zero, size: resolvedSize),
            format: UIGraphicsImageRendererFormat(for: traitCollection)
        ).image { context in
            root.view.layer.render(in: context.cgContext)
        }
    }
}
