//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol FeedImageDataStore {
    typealias RetrievalResult = Swift.Result<Data?, Error>
    typealias InsertionResult = Swift.Result<Void, Error>

    func retrieve(dataForURL url: URL) throws -> Data?
    func insert(_ imageData: Data, for url: URL) throws

    @available(*, deprecated)
    func retrieve(dataForURL url: URL, completion: @escaping (RetrievalResult) -> Void)
    @available(*, deprecated)
    func insert(_ imageData: Data, for url: URL, completion: @escaping (InsertionResult) -> Void)
}

public extension FeedImageDataStore {
    func retrieve(dataForURL url: URL, completion: @escaping (RetrievalResult) -> Void) {}
    func insert(_ imageData: Data, for url: URL, completion: @escaping (InsertionResult) -> Void) {}

    func retrieve(dataForURL url: URL) throws -> Data? {
        var retrievalResult: RetrievalResult?
        let group = DispatchGroup()
        group.enter()
        retrieve(dataForURL: url) { result in
            retrievalResult = result
            group.leave()
        }

        group.wait()
        return try retrievalResult?.get()
    }

    func insert(_ imageData: Data, for url: URL) throws {
        var insertionResult: InsertionResult?
        let group = DispatchGroup()
        group.enter()
        insert(imageData, for: url) { result in
            insertionResult = result
            group.leave()
        }

        group.wait()
        try insertionResult?.get()
    }
}
