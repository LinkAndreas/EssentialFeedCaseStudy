//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class ValidateFeedCacheUseCase: XCTestCase {
    func test_init_doesNotMessageTheStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_validateCache_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()

        sut.validateCache { _ in }
        store.completeRetrieval(with: anyNSError())

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }

    func test_validateCache_doesNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()

        sut.validateCache { _ in }
        store.completeRetrivalWithEmptyCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_validateCache_doesNotDeleteNonExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate: Date = .init()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let nonExpiredTimestamp: Date = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)

        sut.validateCache { _ in }
        store.completeRetrievalSuccessfully(with: feed.locals, timestamp: nonExpiredTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_validateCache_deletesCacheOnExpirationUponRetrieval() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate: Date = .init()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let expirationTimestamp: Date = fixedCurrentDate.minusFeedCacheMaxAge()

        sut.validateCache { _ in }
        store.completeRetrievalSuccessfully(with: feed.locals, timestamp: expirationTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }

    func test_validateCache_deletesExpiredCacheUponRetrieval() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate: Date = .init()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let expiredTimestamp: Date = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)

        sut.validateCache { _ in }
        store.completeRetrievalSuccessfully(with: feed.locals, timestamp: expiredTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }

    func test_validateCache_doesNotDeleteCacheAfterSUTInstanceHasBeenDeallocated() {
        let store: FeedStoreSpy = .init()
        var sut: LocalFeedLoader? = .init(store: store, currentDate: Date.init)

        sut?.validateCache { _ in }
        sut = nil
        store.completeRetrieval(with: anyNSError())

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_validateCache_doesNotMessageStoreUponDeallocation() {
        let store: FeedStoreSpy = .init()
        var sut: LocalFeedLoader? = .init(store: store, currentDate: Date.init)

        sut?.validateCache { _ in }
        sut = nil
        store.completeRetrieval(with: anyNSError())

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_validateCache_failsOnDeletionErrorOfFailedRetrieval() {
        let (sut, spy) = makeSUT()
        let deletionError = anyNSError()

        expect(sut, toCompleteWith: .failure(deletionError), when: {
            spy.completeRetrieval(with: anyNSError())
            spy.completeDeletion(with: deletionError)
        })
    }
    // MARK: - Helper
    private func makeSUT(
        currentDate: @escaping () -> Date = { .init() },
        file: StaticString = #file,
        line: UInt = #line
    ) -> (LocalFeedLoader, FeedStoreSpy) {
        let store: FeedStoreSpy = FeedStoreSpy()
        let sut: LocalFeedLoader = .init(store: store, currentDate: currentDate)

        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }

    private func expect(
        _ sut: LocalFeedLoader,
        toCompleteWith expectedResult: LocalFeedLoader.ValidationResult,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for result!")
        sut.validateCache { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success, .success):
                break

            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(
                    receivedError,
                    expectedError,
                    "Expected to receive \(expectedError), but received \(receivedError) instead.",
                    file: file,
                    line: line
                )

            default:
                XCTFail(
                    "Expected to receive \(expectedResult), but received \(receivedResult) instead.",
                    file: file,
                    line: line
                )
            }

            expectation.fulfill()
        }

        action()

        wait(for: [expectation], timeout: 1.0)
    }
}
