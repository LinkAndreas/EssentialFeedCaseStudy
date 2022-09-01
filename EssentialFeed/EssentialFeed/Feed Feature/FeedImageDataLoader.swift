//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol FeedImageDataLoader {
    func loadImageData(from url: URL) throws -> Data
}
