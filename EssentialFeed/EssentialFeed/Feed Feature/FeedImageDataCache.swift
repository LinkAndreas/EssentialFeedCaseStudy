//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol FeedImageDataCache {
    typealias SaveResult = Swift.Result<Void, Error>

    func save(_ imageData: Data, for url: URL, completion: @escaping (SaveResult) -> Void)
}
