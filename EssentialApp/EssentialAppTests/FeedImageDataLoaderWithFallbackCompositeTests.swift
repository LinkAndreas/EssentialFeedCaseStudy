//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import EssentialApp
import XCTest

class FeedImageDataLoaderWithFallbackCompositeTests: XCTestCase, FeedImageDataLoaderTestCase {
    func test_init_doesNotLoadImageData() {
        let (primaryLoader, fallbackLoader, _) = makeSUT()

        XCTAssertTrue(primaryLoader.loadedURLs.isEmpty, "Expected no loaded urls in the primary loader.")
        XCTAssertTrue(fallbackLoader.loadedURLs.isEmpty, "Expected no loaded urls in the fallback loader.")
    }

    func test_loadImageData_loadsFromPrimaryLoaderFirst() {
        let url = anyURL()
        let (primaryLoader, fallbackLoader, sut) = makeSUT()

        primaryLoader.stubImageLoadResult(with: anyData())
        _ = try? sut.loadImageData(from: url)

        XCTAssertEqual(primaryLoader.loadedURLs, [url], "Expected to load url from primary loader first.")
        XCTAssertTrue(fallbackLoader.loadedURLs.isEmpty, "Expected no loaded urls in the fallback loader.")
    }

    func test_loadImageData_loadsFromFallbackOnPrimaryLoaderFailure() {
        let url = anyURL()
        let (primaryLoader, fallbackLoader, sut) = makeSUT()

        primaryLoader.stubImageLoadResult(with: anyNSError())
        fallbackLoader.stubImageLoadResult(with: anyData())
        _ = try? sut.loadImageData(from: url)

        XCTAssertEqual(primaryLoader.loadedURLs, [url], "Expected to load url from primary loader first.")
        XCTAssertEqual(fallbackLoader.loadedURLs, [url], "Expected to load url from fallback loader afterwards.")
    }

    func test_loadImageData_deliversPrimaryDataOnPrimaryLoaderSuccess() {
        let primaryData = anyData()
        let (primaryLoader, _, sut) = makeSUT()

        expect(sut, toCompleteWith: .success(primaryData), when: {
            primaryLoader.stubImageLoadResult(with: primaryData)
        })
    }

    func test_loadImageData_deliversFallbackDataOnFallbackLoaderSuccess() {
        let fallbackData = anyData()
        let (primaryLoader, fallbackLoader, sut) = makeSUT()

        expect(sut, toCompleteWith: .success(fallbackData), when: {
            primaryLoader.stubImageLoadResult(with: anyNSError())
            fallbackLoader.stubImageLoadResult(with: fallbackData)
        })
    }

    func test_loadImageData_deliversErrorOnBothPrimaryAndFallbackLoaderFailure() {
        let (primaryLoader, fallbackLoader, sut) = makeSUT()

        expect(sut, toCompleteWith: .failure(anyNSError()), when: {
            primaryLoader.stubImageLoadResult(with: anyNSError())
            fallbackLoader.stubImageLoadResult(with: anyNSError())
        })
    }
}

extension FeedImageDataLoaderWithFallbackCompositeTests {
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (FeedImageDataLoaderSpy, FeedImageDataLoaderSpy, FeedImageDataLoaderWithFallbackComposite) {
        let primaryLoader = FeedImageDataLoaderSpy()
        let fallbackLoader = FeedImageDataLoaderSpy()
        let sut = FeedImageDataLoaderWithFallbackComposite(primary: primaryLoader, fallback: fallbackLoader)
        trackForMemoryLeaks(primaryLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (primaryLoader, fallbackLoader, sut)
    }
}
