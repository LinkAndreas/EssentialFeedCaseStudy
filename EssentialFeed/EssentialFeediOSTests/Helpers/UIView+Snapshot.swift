//  Copyright © 2022 Andreas Link. All rights reserved.

import UIKit

extension UIView {
    func snapshot(for configuration: SnapshotConfiguration) -> UIImage {
        layoutMargins = configuration.padding
        backgroundColor = configuration.backgroundColor

        let root = UIViewController()
        root.view = self

        let window = SnapshotWindow(configuration: configuration, root: root)

        setNeedsLayout()
        layoutIfNeeded()
        root.view.setNeedsLayout()
        root.view.layoutIfNeeded()

        let resolvedSize = resolvedSize(for: configuration)
        bounds = .size(resolvedSize)
        window.rootViewController?.view.bounds = bounds

        let offscreen: CGFloat = 10_000
        if configuration.safeAreaInsets == .zero {
            frame.origin = .init(x: offscreen, y: offscreen)
        }

        let image = UIGraphicsImageRenderer(
            bounds: bounds,
            format: UIGraphicsImageRendererFormat(for: configuration.traitCollection)
        ).image { ctx in
            layer.render(in: ctx.cgContext)
        }

        removeFromSuperview()
        root.view = nil
        return image
    }
}
