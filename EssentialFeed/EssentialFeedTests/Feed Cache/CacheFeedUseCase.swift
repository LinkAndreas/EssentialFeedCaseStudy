//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

class CacheFeedUseCase: XCTestCase {
    func test_init_doesNotMessageStoreOnCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()

        sut.save([uniqueImage(), uniqueImage()]) { _ in }

        XCTAssertEqual(store.deletionCompletions.count, 1)
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError: Error = anyNSError()

        sut.save(uniqueImageFeed().models) { _ in }
        store.completeDeletion(with: deletionError, atIndex: 0)

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }

    func test_save_requestsNewCacheInsertionWithTimestampOnCacheDeletion() {
        let (models, locals) = uniqueImageFeed()
        let timestamp: Date = .init()
        let (sut, store) = makeSUT(currentDate: { timestamp })

        sut.save(models) { _ in }
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(feed: locals, timestamp: timestamp)])
    }

    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError: NSError = anyNSError()

        expect(sut, toCompleteWith: .failure(deletionError), when: {
            store.completeDeletion(with: deletionError)
        })
    }

    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let insertionError: NSError = anyNSError()

        expect(sut, toCompleteWith: .failure(insertionError), when: {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        })
    }

    func test_save_suceedsOnSuccessfulInsertion() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success(()), when: {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        })
    }

    func test_save_doesNotDeliverResultAfterDeletionErrorOnDeallocation() {
        let store: FeedStoreSpy = .init()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store) { .init() }
        let deletionError: NSError = anyNSError()

        var receivedResult: Result<Void, Error>?
        sut?.save(uniqueImageFeed().models) { result in
            receivedResult = result
        }

        sut = nil
        store.completeDeletion(with: deletionError)

        XCTAssertNil(receivedResult, "Result should not have been delivered")
    }

    func test_save_doesNotDeliverResultAfterInsertionErrorOnDeallocation() {
        let store: FeedStoreSpy = .init()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store) { .init() }
        let insertionError: NSError = anyNSError()

        var receivedResult: Result<Void, Error>?
        sut?.save(uniqueImageFeed().models) { result in
            receivedResult = result
        }

        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: insertionError)

        XCTAssertNil(receivedResult, "Result should not have been delivered")
    }

    // MARK: - Helpers
    private func expect(
        _ sut: LocalFeedLoader,
        toCompleteWith expectedResult: Result<Void, Error>,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp: XCTestExpectation = .init(description: "expectation")
        var receivedResult: Result<Void, Error>?

        sut.save(uniqueImageFeed().models) { result in
            switch result {
            case .success:
                receivedResult = .success(())

            case let .failure(error as NSError):
                receivedResult = .failure(error)
            }

            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1.0)

        switch (receivedResult, expectedResult) {
        case (.success, .success):
            return

        case let (.failure(error1 as NSError), .failure(error2 as NSError)):
            XCTAssertEqual(error1, error2)

        default:
            XCTFail("Expected \(String(describing: receivedResult)) to equl \(expectedResult)", file: file, line: line)
        }
    }

    private func makeSUT(
        currentDate: @escaping () -> Date = { .init() },
        file: StaticString = #file,
        line: UInt = #line
    ) -> (LocalFeedLoader, FeedStoreSpy) {
        let store: FeedStoreSpy = .init()
        let sut: LocalFeedLoader = .init(store: store, currentDate: currentDate)

        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (sut, store)
    }
}


