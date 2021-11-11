//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol FeedImageDataLoaderTask {
    func cancel()
}

public protocol FeedImageDataLoader {
    typealias Result = Swift.Result<Data?, Error>
    typealias InsertionResult = Swift.Result<Void, Error>

    func loadImageData(from url: URL, completion: @escaping (Result) -> Void) -> FeedImageDataLoaderTask
    func save(_ imageData: Data, for url: URL, completion: @escaping (InsertionResult) -> Void)
}
