//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class LoadFeedFromCacheUseCase: XCTestCase {
    func test_init_shouldNotDeleteCache() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    // MARK: - Helper
    private func makeSUT() -> (LocalFeedLoader, FeedStoreSpy) {
        let store: FeedStoreSpy = FeedStoreSpy()
        let sut: LocalFeedLoader = .init(store: store, currentDate: { Date.init() })

        return (sut, store)
    }

    private class FeedStoreSpy: FeedStore {
        enum Message: Equatable {
            case deleteCachedFeed
            case insert(feed: [LocalFeedImage], timestamp: Date)
        }

        var receivedMessages: [Message] = []
        var deletionCompletions: [DeletionCompletion] = []
        var insertionCompletions: [InsertionCompletion] = []

        func insert(feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
            insertionCompletions.append(completion)
            receivedMessages.append(.insert(feed: feed, timestamp: timestamp))
        }

        func deleteCachedFeed(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            receivedMessages.append(.deleteCachedFeed)
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
    }
}
