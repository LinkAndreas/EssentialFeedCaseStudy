//  Copyright © 2021 Andreas Link. All rights reserved.

import XCTest
import EssentialFeed

final class FeedLoaderCacheDecorator: FeedLoader {
    private let decoratee: FeedLoader

    init(decoratee: FeedLoader) {
        self.decoratee = decoratee
    }

    func fetchFeed(completion: @escaping (FeedLoader.Result) -> Void) {
        decoratee.fetchFeed(completion: completion)
    }
}

final class FeedLoaderCacheDecoratorTests: XCTestCase, FeedLoaderTestCase {
    func test_load_deliversFeedOnLoaderSuccess() {
        let feed = uniqueFeed()
        let sut = makeSUT(loaderResult: .success(feed))

        expect(sut, toCompleteWith: .success(feed))
    }

    func test_load_deliversErrorOnLoaderFailure() {
        let sut = makeSUT(loaderResult: .failure(anyNSError()))

        expect(sut, toCompleteWith: .failure(anyNSError()))
    }
}

extension FeedLoaderCacheDecoratorTests {
    private func makeSUT(
        loaderResult: FeedLoader.Result,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FeedLoaderCacheDecorator {
        let feedLoader = FeedLoaderStub(result: loaderResult)
        let sut = FeedLoaderCacheDecorator(decoratee: feedLoader)
        trackForMemoryLeaks(feedLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
