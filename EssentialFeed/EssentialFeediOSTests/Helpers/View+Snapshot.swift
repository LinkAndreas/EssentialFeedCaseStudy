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

extension View {
    private func resolvedSize(for configuration: SnapshotConfiguration) -> CGSize {
        resolve(size: configuration.size)
            .adding(configuration.padding)
    }

    private func resolve(size: CGSize) -> CGSize {
        switch (size.width, size.height) {
        case (UIView.layoutFittingCompressedSize.width, UIView.layoutFittingCompressedSize.height):
            let rootView = fixedSize()
            let controller = UIHostingController(rootView: rootView)

            return controller.sizeThatFits(in: UIView.layoutFittingCompressedSize)

        case let (UIView.layoutFittingCompressedSize.width, height):
            let rootView = frame(height: height).fixedSize()
            let controller = UIHostingController(rootView: rootView)

            return controller.sizeThatFits(in: UIView.layoutFittingCompressedSize)

        case let (width, UIView.layoutFittingCompressedSize.height):
            let rootView = frame(width: width).fixedSize()
            let controller = UIHostingController(rootView: rootView)

            return controller.sizeThatFits(in: UIView.layoutFittingCompressedSize)

        case let (width, height):
            let rootView = frame(width: width, height: height).fixedSize()
            let controller = UIHostingController(rootView: rootView)

            return controller.sizeThatFits(in: UIView.layoutFittingCompressedSize)
        }
    }
}
