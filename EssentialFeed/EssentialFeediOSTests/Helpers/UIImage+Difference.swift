//  Copyright © 2022 Andreas Link. All rights reserved.

import UIKit

extension UIImage {
    func diff(with reference: UIImage) -> UIImage {
        let combinedSize = CGSize(
            width: max(size.width, reference.size.width),
            height: max(size.height, reference.size.height)
        )

        UIGraphicsBeginImageContextWithOptions(combinedSize, true, 0)
        let context: CGContext = UIGraphicsGetCurrentContext()!

        // Draw first image
        draw(in: CGRect(origin: .zero, size: size))

        // Draw second image
        context.setAlpha(0.5)
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        reference.draw(in: CGRect(origin: .zero, size: size))

        // Draw difference
        context.setBlendMode(.difference)
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        context.endTransparencyLayer()

        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return image
    }
}
