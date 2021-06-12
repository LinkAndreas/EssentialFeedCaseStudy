//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed

internal class FeedStoreSpy: FeedStore {
    enum Message: Equatable {
        case deleteCachedFeed
        case insert(feed: [LocalFeedImage], timestamp: Date)
        case retrieve
    }

    var receivedMessages: [Message] = []
    var deletionCompletions: [DeletionCompletion] = []
    var insertionCompletions: [InsertionCompletion] = []
    var retrievalCompletions: [RetrievalCompletion] = []

    func insert(feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(feed: feed, timestamp: timestamp))
    }

    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }

    func retrieve(completion: @escaping RetrievalCompletion) {
        retrievalCompletions.append(completion)
        receivedMessages.append(.retrieve)
    }

    func completeDeletion(with error: Error, atIndex index: Int = 0) {
        deletionCompletions[index](.failure(error))
    }

    func completeDeletionSuccessfully(atIndex index: Int = 0) {
        deletionCompletions[index](.success(()))
    }

    func completeInsertion(with error: Error, atIndex index: Int = 0) {
        insertionCompletions[index](.failure(error))
    }

    func completeInsertionSuccessfully(atIndex index: Int = 0) {
        insertionCompletions[index](.success(()))
    }

    func completeRetrieval(with error: Error, atIndex index: Int = 0) {
        retrievalCompletions[index](.failure(error: error))
    }

    func completeRetrivalWithEmptyCache(atIndex index: Int = 0) {
        retrievalCompletions[index](.empty)
    }

    func completeRetrievalSuccessfully(atIndex index: Int = 0, with feed: [LocalFeedImage], timestamp:  Date) {
        retrievalCompletions[index](.found(feed: feed, timestamp: timestamp))
    }
}
