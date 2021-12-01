//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class LoadFeedFromCacheUseCase: XCTestCase {
    func test_init_shouldNotDeleteCache() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_load_requestsCacheRetrival() {
        let (sut, store) = makeSUT()

        sut.fetchFeed { _ in }

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_deliversErrorOnRetrievalError() {
        let expectedError: NSError = anyNSError()
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .failure(expectedError), when: {
            store.completeRetrieval(with: expectedError)
        })
    }

    func test_load_deliversNoFeedOnEmptyCache() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrivalWithEmptyCache()
        })
    }

    func test_load_deliversCachedImagesOnNonExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate: Date = .init()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let nonExpiredTimestamp: Date = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)

        expect(sut, toCompleteWith: .success(feed.models), when: {
            store.completeRetrievalSuccessfully(with: feed.locals, timestamp: nonExpiredTimestamp)
        })
    }

    func test_load_deliversNoFeedImagesOnCacheExpiration() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate: Date = .init()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let expirationTimestamp: Date = fixedCurrentDate.minusFeedCacheMaxAge()

        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrievalSuccessfully(with: feed.locals, timestamp: expirationTimestamp)
        })
    }

    func test_load_deliversNoFeedImagesOnExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate: Date = .init()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let expiredTimestamp: Date = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)

        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrievalSuccessfully(with: feed.locals, timestamp: expiredTimestamp)
        })
    }

    func test_load_hasNoSideEffectOnRetrievalError() {
        let (sut, store) = makeSUT()

        sut.fetchFeed { _ in }
        store.completeRetrieval(with: anyNSError())

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_hasNoSideEffectOnEmptyCache() {
        let (sut, store) = makeSUT()

        sut.fetchFeed { _ in }
        store.completeRetrivalWithEmptyCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_hasNoSideEffectOnNonExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate: Date = .init()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let nonExpiredTimestamp: Date = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)

        sut.fetchFeed { _ in }
        store.completeRetrievalSuccessfully(with: feed.locals, timestamp: nonExpiredTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_hasNoSideEffectOnCacheExpirationUponRetrieval() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate: Date = .init()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let expirationTimestamp: Date = fixedCurrentDate.minusFeedCacheMaxAge()

        sut.fetchFeed { _ in }
        store.completeRetrievalSuccessfully(with: feed.locals, timestamp: expirationTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_hasNoSideEffectOnExpiredCacheUponRetrieval() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate: Date = .init()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let expiredTimestamp: Date = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)

        sut.fetchFeed { _ in }
        store.completeRetrievalSuccessfully(with: feed.locals, timestamp: expiredTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_doesNotDeliverResultUponDeallocation() {
        let store: FeedStoreSpy = .init()
        var sut: LocalFeedLoader? = .init(store: store, currentDate: Date.init)

        sut?.fetchFeed { _ in }
        sut = nil
        store.completeRetrivalWithEmptyCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve])
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
        toCompleteWith expectedResult: LocalFeedLoader.LoadResult,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp: XCTestExpectation = .init(description: "Wait for load result.")
        var receivedResult: LocalFeedLoader.LoadResult?

        sut.fetchFeed { result in
            receivedResult = result
            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1.0)

        switch (receivedResult, expectedResult) {
        case let (.success(receivedFeed), .success(expectedFeed)):
            XCTAssertEqual(
                receivedFeed,
                expectedFeed,
                "Expected \(expectedFeed), but recived \(receivedFeed) instead.",
                file: file,
                line: line
            )

        case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
            XCTAssertEqual(
                receivedError,
                expectedError,
                "Expected \(expectedError), but recived \(receivedError) instead.",
                file: file,
                line: line
            )

        default:
            XCTFail(
                "Expected \(expectedResult), but received \(String(describing: receivedResult)) instead",
                file: file,
                line: line
            )
        }
    }
}


