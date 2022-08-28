//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol FeedImageDataCache {
    func save(_ imageData: Data, for url: URL) throws
}
