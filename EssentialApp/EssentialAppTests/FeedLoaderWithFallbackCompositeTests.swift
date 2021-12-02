//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import EssentialApp
import XCTest

class FeedLoaderWithFallbackCompositeTests: XCTestCase, FeedLoaderTestCase {
    func test_load_deliversPrimaryFeedOnPrimaryLoaderSuccess() {
        let primaryFeed = uniqueFeed()
        let fallbackFeed = uniqueFeed()
        let sut = makeSUT(primaryResult: .success(primaryFeed), fallbackResult: .success(fallbackFeed))

        expect(sut, toCompleteWith: .success(primaryFeed))
    }

    func test_load_deliversFallbackFeedOnPrimaryLoaderFailure() {
        let fallbackFeed = uniqueFeed()
        let sut = makeSUT(primaryResult: .failure(anyNSError()), fallbackResult: .success(fallbackFeed))

        expect(sut, toCompleteWith: .success(fallbackFeed))
    }

    func test_load_deliversFailureOnBothPrimaryAndFallbackLoaderFailure() {
        let fallbackError = anyNSError()
        let sut = makeSUT(primaryResult: .failure(anyNSError()), fallbackResult: .failure(fallbackError))

        expect(sut, toCompleteWith: .failure(fallbackError))
    }
}

extension FeedLoaderWithFallbackCompositeTests {
    private func makeSUT(
        primaryResult: FeedLoader.Result,
        fallbackResult: FeedLoader.Result
    ) -> FeedLoaderWithFallbackComposite {
        let primaryLoader = FeedLoaderStub(result: primaryResult)
        let fallbackLoader = FeedLoaderStub(result: fallbackResult)
        let sut = FeedLoaderWithFallbackComposite(primary: primaryLoader, fallback: fallbackLoader)
        trackForMemoryLeaks(primaryLoader)
        trackForMemoryLeaks(fallbackLoader)
        trackForMemoryLeaks(sut)
        return sut
    }
}
