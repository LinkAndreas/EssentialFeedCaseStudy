//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol FeedImageDataStore {
    typealias RetrievalResult = Swift.Result<Data?, Error>
    typealias InsertionResult = Swift.Result<Void, Error>

    func retrieve(dataForURL url: URL, completion: @escaping (RetrievalResult) -> Void)
    func insert(_ imageData: Data, for url: URL, completion: @escaping (InsertionResult) -> Void)
}
