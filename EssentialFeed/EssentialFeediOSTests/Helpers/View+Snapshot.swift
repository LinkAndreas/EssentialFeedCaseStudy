//  Copyright © 2022 Andreas Link. All rights reserved.

import SwiftUI

extension View {
    func snapshot(for configuration: SnapshotConfiguration) -> UIImage {
        let root = UIHostingController(rootView: self)

        root.view.backgroundColor = configuration.backgroundColor

        let window = SnapshotWindow(configuration: configuration, root: root)

        root.view.setNeedsLayout()
        root.view.layoutIfNeeded()

        let resolvedSize = resolvedSize(for: configuration)
        root.view.bounds = .size(resolvedSize)
        window.rootViewController?.view.bounds = root.view.bounds

        let offscreen: CGFloat = 10_000
        if configuration.safeAreaInsets == .zero {
            root.view.frame.origin = .init(x: offscreen, y: offscreen)
        }

        return UIGraphicsImageRenderer(
            bounds: root.view.bounds,
            format: UIGraphicsImageRendererFormat(for: configuration.traitCollection)
        ).image { ctx in
            root.view.layer.render(in: ctx.cgContext)
        }
    }
}
