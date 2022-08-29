//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol FeedImageDataStore {
    func retrieve(dataForURL url: URL) throws -> Data?
    func insert(_ imageData: Data, for url: URL) throws
}
