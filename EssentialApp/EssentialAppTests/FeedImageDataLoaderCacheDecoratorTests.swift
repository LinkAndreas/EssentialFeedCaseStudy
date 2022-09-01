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

        loaderSpy.stubImageLoadResult(with: anyData())
        _ = try? sut.loadImageData(from: url)

        XCTAssertEqual(loaderSpy.loadedURLs, [url], "Expected to load url from loader")
    }

    func test_loadImageData_deliversDataOnLoaderSuccess() {
        let imageData = anyData()
        let (loaderSpy, sut) = makeSUT()

        expect(sut, toCompleteWith: .success(imageData), when: {
            loaderSpy.stubImageLoadResult(with: imageData)
        })
    }

    func test_loadImageData_deliversErrorOnLoaderFailure() {
        let (loaderSpy, sut) = makeSUT()

        expect(sut, toCompleteWith: .failure(anyNSError()), when: {
            loaderSpy.stubImageLoadResult(with: anyNSError())
        })
    }

    func test_loadImageData_cachesLoadedDataOnLoaderSuccess() {
        let url = anyURL()
        let imageData = anyData()
        let cache = ImageDataCacheSpy()
        let (loaderSpy, sut) = makeSUT(cache: cache)

        loaderSpy.stubImageLoadResult(with: imageData)
        _ = try? sut.loadImageData(from: url)

        XCTAssertEqual(cache.messages, [.save(imageData: imageData)], "Expected to cache loaded image data on success.")
    }

    func test_loadImageData_doesNotCacheOnLoaderFailure() {
        let url = anyURL()
        let cache = ImageDataCacheSpy()
        let (loaderSpy, sut) = makeSUT(cache: cache)

        loaderSpy.stubImageLoadResult(with: anyNSError())
        _ = try? sut.loadImageData(from: url)

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
        private var saveResult: Result<Void, Error>?

        func save(_ imageData: Data, for url: URL) throws {
            messages.append(.save(imageData: imageData))
            try saveResult?.get()
        }

        func complete(with result: Result<Void, Error>) {
            saveResult = result
        }
    }
}
