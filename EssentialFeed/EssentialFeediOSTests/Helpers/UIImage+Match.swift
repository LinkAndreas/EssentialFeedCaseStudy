//  Copyright © 2022 Andreas Link. All rights reserved.

import UIKit

extension UIImage {
    func matches(
        reference: UIImage,
        perPixelTolerance: CGFloat,
        tolerance: CGFloat,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Bool {
        guard
            let original = cgImage,
            let reference = reference.cgImage,
            original.width == reference.width,
            original.height == reference.height,
            let lhsRawPixel = makeRawPixels(from: original),
            let rhsRawPixel = makeRawPixels(from: reference)
        else {
            return false
        }

        if tolerance == 0, perPixelTolerance == 0 {
            return lhsRawPixel.matches(reference: rhsRawPixel)
        } else {
            return lhsRawPixel.matchesPixelWise(
                reference: rhsRawPixel,
                width: original.width,
                height: original.height,
                perPixelTolerance: perPixelTolerance,
                tolerance: tolerance
            )
        }
    }
}

extension UIImage {
    private func makeRawPixels(from image: CGImage?) -> [UInt32]? {
        guard let image = image else { return nil }

        let width = image.width
        let height = image.height
        let size = CGSize(width: width, height: height)
        let totalCount: Int = width * height

        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        )

        context?.draw(image, in: CGRect(origin: .zero, size: size))

        guard let imageData = context?.data else { return nil }

        let pointer = imageData.bindMemory(to: UInt32.self, capacity: totalCount)
        let bufferPointer = UnsafeBufferPointer(start: pointer, count: totalCount)
        return Array(bufferPointer)
    }
}

private extension Array where Element == UInt32 {
    func matches(reference: [Element]) -> Bool {
        self == reference
    }

    func matchesPixelWise(
        reference: [Element],
        width: Int,
        height: Int,
        perPixelTolerance: CGFloat,
        tolerance: CGFloat
    ) -> Bool {
        var distinctPixelCount: UInt = 0

        for (x, y) in zip(0 ..< width, 0 ..< height) {
            let original: Pixel = Pixel(rawValue: self[y * width + x])
            let reference: Pixel = Pixel(rawValue: reference[y * width + x])

            if !original.matches(reference: reference, perPixelTolerance: perPixelTolerance) {
                distinctPixelCount += 1
                let percentage: CGFloat = CGFloat(distinctPixelCount) / CGFloat(width * height);
                if percentage > tolerance { return false }
            }
        }

        return true
    }
}

private struct Pixel: Equatable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(rawValue: UInt32) {
        self.init(
            red: CGFloat(UInt8((rawValue >> 16) & 255)) / 255,
            green: CGFloat(UInt8((rawValue >> 8) & 255)) / 255,
            blue: CGFloat(UInt8((rawValue >> 0) & 255)) / 255,
            alpha: CGFloat(UInt8((rawValue >> 24) & 255)) / 255
        )
    }

    func matches(reference: Pixel, perPixelTolerance: CGFloat) -> Bool {
        guard self != reference else { return true }
        guard perPixelTolerance > 0 else { return false }

        let redDiff: CGFloat = CGFloat(abs(red - reference.red)) / 256
        let greenDiff: CGFloat = CGFloat(abs(green - reference.green)) / 256
        let blueDiff: CGFloat = CGFloat(abs(blue - reference.blue)) / 256
        let alphaDiff: CGFloat = CGFloat(abs(alpha - reference.alpha)) / 256

        let differenceFound: Bool = false
            || redDiff > perPixelTolerance
            || greenDiff > perPixelTolerance
            || blueDiff > perPixelTolerance
            || alphaDiff > perPixelTolerance

        return !differenceFound
    }
}
