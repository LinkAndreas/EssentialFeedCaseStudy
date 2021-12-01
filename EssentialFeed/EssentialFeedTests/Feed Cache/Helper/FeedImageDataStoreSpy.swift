//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import Foundation

class FeedImageDataStoreSpy: FeedImageDataStore {
    enum Message: Equatable {
        case retrieve(dataFor: URL)
        case insert(imageData: Data, url: URL)
    }

    private (set) var receivedMessages: [Message] = []
    private var retrievalCompletions: [(FeedImageDataStore.RetrievalResult) -> Void] = []
    private var insertionCompletions: [(FeedImageDataStore.InsertionResult) -> Void] = []

    func retrieve(dataForURL url: URL, completion: @escaping (FeedImageDataStore.RetrievalResult) -> Void) {
        receivedMessages.append(.retrieve(dataFor: url))
        retrievalCompletions.append(completion)
    }

    func insert(_ imageData: Data, for url: URL, completion: @escaping (FeedImageDataStore.InsertionResult) -> Void) {
        receivedMessages.append(.insert(imageData: imageData, url: url))
        insertionCompletions.append(completion)
    }

    func completeDataRetrieval(with result: FeedImageDataStore.RetrievalResult, atIndex index: Int = 0) {
        retrievalCompletions[index](result)
    }

    func completeDataInsertion(with result: FeedImageDataStore.InsertionResult, atIndex index: Int = 0) {
        insertionCompletions[index](result)
    }
}
