//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialApp
import EssentialFeed
import XCTest

final class FeedImageDataLoaderCacheDecoratorTests: XCTestCase, FeedImageDataLoaderTestCase {
    func test_init_doesNotLoadImageData() {
        let (loaderSpy, _) = makeSUT()

        XCTAssertTrue(loaderSpy.loadedURLs.isEmpty, "Expected loaded URLs")
    }

    func test_loadImageData_loadsFromLoader() {
        let url = anyURL()
        let (loaderSpy, sut) = makeSUT()

        _ = sut.loadImageData(from: url) { _ in }

        XCTAssertEqual(loaderSpy.loadedURLs, [url], "Expected to load url from loader")
    }

    func test_cancelLoadImageData_cancelsLoaderTask() {
        let url = anyURL()
        let (loaderSpy, sut) = makeSUT()

        let task = sut.loadImageData(from: url) { _ in }
        task.cancel()

        XCTAssertEqual(loaderSpy.cancelledURLs, [url], "Expected to cancel URL loading from loader")
    }

    func test_loadImageData_deliversDataOnLoaderSuccess() {
        let imageData = anyData()
        let (loaderSpy, sut) = makeSUT()

        expect(sut, toCompleteWith: .success(imageData), when: {
            loaderSpy.complete(with: imageData)
        })
    }

    func test_loadImageData_deliversErrorOnLoaderFailure() {
        let (loaderSpy, sut) = makeSUT()

        expect(sut, toCompleteWith: .failure(anyNSError()), when: {
            loaderSpy.complete(with: anyNSError())
        })
    }

    func test_loadImageData_cachesLoadedDataOnLoaderSuccess() {
        let url = anyURL()
        let imageData = anyData()
        let cache = ImageDataCacheSpy()
        let (loaderSpy, sut) = makeSUT(cache: cache)

        _ = sut.loadImageData(from: url) { _ in }
        loaderSpy.complete(with: imageData)

        XCTAssertEqual(cache.messages, [.save(imageData: imageData)], "Expected to cache loaded image data on success.")
    }

    func test_loadImageData_doesNotCacheOnLoaderFailure() {
        let url = anyURL()
        let cache = ImageDataCacheSpy()
        let (_, sut) = makeSUT(cache: cache)

        _ = sut.loadImageData(from: url) { _ in }

        XCTAssertTrue(cache.messages.isEmpty, "Expected not to cache image data on load error.")
    }
}

extension FeedImageDataLoaderCacheDecoratorTests {
    private func makeSUT(
        cache: ImageDataCacheSpy = .init(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (FeedImageDataLoaderSpy, FeedImageDataLoaderCacheDecorator) {
        let loaderSpy = FeedImageDataLoaderSpy()
        let sut = FeedImageDataLoaderCacheDecorator(decoratee: loaderSpy, cache: cache)
        trackForMemoryLeaks(loaderSpy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (loaderSpy, sut)
    }

    final class ImageDataCacheSpy: FeedImageDataCache {
        enum Message: Equatable {
            case save(imageData: Data)
        }

        private (set) var messages: [Message] = []
        private var completions: [(SaveResult) -> Void] = []

        func save(_ imageData: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {
            messages.append(.save(imageData: imageData))
            completions.append(completion)
        }

        func complete(with result: SaveResult, atIndex index: Int = 0) {
            completions[index](result)
        }
    }
}
