//  Copyright © 2022 Andreas Link. All rights reserved.

import SwiftUI

extension View {
    func resolvedSize(for configuration: SnapshotConfiguration) -> CGSize {
        resolve(width: configuration.width, height: configuration.height)
            .adding(configuration.padding)
    }

    func resolve(width: Dimension, height: Dimension) -> CGSize {
        switch (width, height) {
        case (.compressed, .compressed):
            let rootView = fixedSize()
            let controller = UIHostingController(rootView: rootView)

            return controller.sizeThatFits(in: UIView.layoutFittingCompressedSize)

        case let (.compressed, .value(height)):
            let rootView = frame(height: height).fixedSize()
            let controller = UIHostingController(rootView: rootView)

            return controller.sizeThatFits(in: UIView.layoutFittingCompressedSize)

        case let (.value(width), .compressed):
            let rootView = frame(width: width).fixedSize()
            let controller = UIHostingController(rootView: rootView)

            return controller.sizeThatFits(in: UIView.layoutFittingCompressedSize)

        case let (.value(width), .value(height)):
            let rootView = frame(width: width, height: height).fixedSize()
            let controller = UIHostingController(rootView: rootView)

            return controller.sizeThatFits(in: UIView.layoutFittingCompressedSize)
        }
    }
}
