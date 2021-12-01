//
//  EssentialAppTests.swift
//  EssentialAppTests
//
//  Created by Andreas Link on 01.12.21.
//

import EssentialFeed
import EssentialApp
import XCTest

final class FeedImageDataLoaderWithFallbackComposite: FeedImageDataLoader {
    private final class Task: FeedImageDataLoaderTask {
        func cancel() {}
    }

    private let primary: FeedImageDataLoader
    private let fallback: FeedImageDataLoader

    init(primary: FeedImageDataLoader, fallback: FeedImageDataLoader) {
        self.primary = primary
        self.fallback = fallback
    }

    func loadImageData(from url: URL, completion: @escaping (LoadResult) -> Void) -> FeedImageDataLoaderTask {
        _ = primary.loadImageData(from: url) { _ in }
        return Task()
    }
}

class FeedImageDataLoaderWithFallbackTests: XCTestCase {
    func test_init_doesNotLoadImageData() {
        let (primaryLoader, fallbackLoader, _) = makeSUT()

        XCTAssertTrue(primaryLoader.loadedURLs.isEmpty, "Expected no loaded urls in the primary loader.")
        XCTAssertTrue(fallbackLoader.loadedURLs.isEmpty, "Expected no loaded urls in the fallback loader.")
    }

    func test_load_loadsFromPrimaryLoaderFirst() {
        let url = anyURL()
        let (primaryLoader, fallbackLoader, sut) = makeSUT()

        _ = sut.loadImageData(from: url) { _ in }

        XCTAssertEqual(primaryLoader.loadedURLs, [url], "Expected to load url from primary loader first.")
        XCTAssertTrue(fallbackLoader.loadedURLs.isEmpty, "Expected no loaded urls in the fallback loader.")
    }
}

extension FeedImageDataLoaderWithFallbackTests {
    private func makeSUT() -> (LoaderSpy, LoaderSpy, FeedImageDataLoaderWithFallbackComposite) {
        let primaryLoader = LoaderSpy()
        let fallbackLoader = LoaderSpy()
        return (
            primaryLoader,
            fallbackLoader,
            FeedImageDataLoaderWithFallbackComposite(
                primary: primaryLoader,
                fallback: fallbackLoader
            )
        )
    }

    final class LoaderSpy: FeedImageDataLoader {
        private final class Task: FeedImageDataLoaderTask {
            func cancel() {}
        }

        private (set) var receivedMessages: [(url: URL, completion: ((LoadResult) -> Void))] = []
        var loadedURLs: [URL] { receivedMessages.map(\.url) }

        func loadImageData(from url: URL, completion: @escaping (LoadResult) -> Void) -> FeedImageDataLoaderTask {
            receivedMessages.append((url, completion))
            return Task()
        }
    }

    private func expect(
        _ sut: FeedLoaderWithFallbackComposite,
        toCompleteWith expectedResult: FeedLoader.Result,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for result.")
        sut.fetchFeed { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedFeed), .success(expectedFeed)):
                XCTAssertEqual(
                    receivedFeed,
                    expectedFeed,
                    "Expected to receive \(expectedFeed), but received \(receivedFeed) instead.",
                    file: file,
                    line: line
                )

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

        wait(for: [expectation], timeout: 1.0)
    }

    private func anyData() -> Data {
        return "Any data".data(using: .utf8)!
    }

    private func anyURL() -> URL {
        return URL(string: "http://any.url")!
    }

    private func anyNSError() -> NSError {
        return .init(domain: "any domain", code: 42, userInfo: nil)
    }
}
