//  Copyright © 2022 Andreas Link. All rights reserved.

import UIKit

extension UIViewController {
    func snapshot(for configuration: SnapshotConfiguration) -> UIImage {
        view.layoutMargins = configuration.padding
        view.backgroundColor = configuration.backgroundColor

        let window = SnapshotWindow(configuration: configuration, root: self)

        view.setNeedsLayout()
        view.layoutIfNeeded()

        let resolvedSize = view.resolvedSize(for: configuration)
        view.bounds = .init(
            x: view.safeAreaInsets.left,
            y: -view.safeAreaInsets.top,
            width: resolvedSize.width,
            height: resolvedSize.height
        )
        window.rootViewController?.view.bounds = view.bounds

        let offscreen: CGFloat = 10_000
        if configuration.safeAreaInsets == .zero {
            view.frame.origin = .init(x: offscreen, y: offscreen)
        }

        return UIGraphicsImageRenderer(
            bounds: view.bounds,
            format: UIGraphicsImageRendererFormat(for: configuration.traitCollection)
        ).image { ctx in
            view.layer.render(in: ctx.cgContext)
        }
    }
}
