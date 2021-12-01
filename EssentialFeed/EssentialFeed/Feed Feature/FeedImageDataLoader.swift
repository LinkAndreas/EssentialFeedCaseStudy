//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol FeedImageDataLoaderTask {
    func cancel()
}

public protocol FeedImageDataLoader {
    typealias LoadResult = Swift.Result<Data, Error>

    func loadImageData(from url: URL, completion: @escaping (LoadResult) -> Void) -> FeedImageDataLoaderTask
}
