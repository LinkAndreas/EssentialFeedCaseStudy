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

        sut.loadFeed { _ in }

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_deliversErrorOnRetrievalError() {
        let expectedError: NSError = anyNSError()
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .failure(expectedError), when: {
            store.completeLoad(with: expectedError)
        })
    }

    func test_load_deliversNoFeedOnEmptyCache() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success([]), when: {
            store.completeLoadSuccessfully(with: [])
        })
    }

    // MARK: - Helper
    private func makeSUT() -> (LocalFeedLoader, FeedStoreSpy) {
        let store: FeedStoreSpy = FeedStoreSpy()
        let sut: LocalFeedLoader = .init(store: store, currentDate: { Date.init() })

        return (sut, store)
    }

    private func anyNSError() -> NSError {
        return .init(domain: "any domain", code: 42, userInfo: nil)
    }

    private func expect(
        _ sut: LocalFeedLoader,
        toCompleteWith expectedResult: LocalFeedLoader.LoadResult,
        when action: () -> Void
    ) {
        let exp: XCTestExpectation = .init(description: "Wait for load result.")
        var receivedResult: LocalFeedLoader.LoadResult?

        sut.loadFeed { result in
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
                "Expected \(expectedFeed), but recived \(receivedFeed) instead."
            )

        case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
            XCTAssertEqual(
                receivedError,
                expectedError,
                "Expected \(expectedError), but recived \(receivedError) instead."
            )

        default:
            XCTFail("Expected \(expectedResult), but received \(String(describing: receivedResult)) instead")
        }
    }
}
