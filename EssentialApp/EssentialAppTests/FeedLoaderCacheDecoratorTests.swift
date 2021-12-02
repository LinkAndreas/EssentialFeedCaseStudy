//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialApp
import EssentialFeed
import XCTest

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

    func test_load_cachesLoadedFeedOnLoaderSuccess() {
        let cache = CacheSpy()
        let feed = uniqueFeed()
        let sut = makeSUT(loaderResult: .success(feed), cache: cache)

        sut.fetchFeed { _ in }

        XCTAssertEqual(cache.messages, [.save(feed: feed)], "Expected to cache loaded feed on success.")
    }

    func test_load_doesNotCacheOnLoaderFailure() {
        let cache = CacheSpy()
        let sut = makeSUT(loaderResult: .failure(anyNSError()), cache: cache)
        sut.fetchFeed { _ in }

        XCTAssertTrue(cache.messages.isEmpty, "Expected not to cache feed on load error.")
    }
}

extension FeedLoaderCacheDecoratorTests {
    private func makeSUT(
        loaderResult: FeedLoader.Result,
        cache: CacheSpy = .init(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FeedLoaderCacheDecorator {
        let feedLoader = FeedLoaderStub(result: loaderResult)
        let sut = FeedLoaderCacheDecorator(decoratee: feedLoader, cache: cache)
        trackForMemoryLeaks(feedLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    final class CacheSpy: FeedCache {
        enum Message: Equatable {
            case save(feed: [FeedImage])
        }

        private (set) var messages: [Message] = []
        private var completions: [(SaveResult) -> Void] = []

        func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
            messages.append(.save(feed: feed))
            completions.append(completion)
        }

        func complete(with result: SaveResult, atIndex index: Int = 0) {
            completions[index](result)
        }
    }
}
