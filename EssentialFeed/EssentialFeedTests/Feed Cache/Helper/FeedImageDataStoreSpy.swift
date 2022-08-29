//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import Foundation

class FeedImageDataStoreSpy: FeedImageDataStore {
    enum Message: Equatable {
        case retrieve(dataFor: URL)
        case insert(imageData: Data, url: URL)
    }

    private (set) var receivedMessages: [Message] = []
    private var retrievalResult: Result<Data?, Error>?
    private var insertionResult: Result<Void, Error>?

    func retrieve(dataForURL url: URL) throws -> Data? {
        receivedMessages.append(.retrieve(dataFor: url))
        return try retrievalResult?.get()
    }

    func insert(_ imageData: Data, for url: URL) throws {
        receivedMessages.append(.insert(imageData: imageData, url: url))
        try insertionResult?.get()
    }

    func stubRetrievalResult(with result: Result<Data?, Error>) {
        retrievalResult = result
    }

    func stubInsertionResult(with result: Result<Void, Error>) {
        insertionResult = result
    }
}
