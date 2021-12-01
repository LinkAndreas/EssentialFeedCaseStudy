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
        _ = primary.loadImageData(from: url) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                break

            case .failure:
                _ = self.fallback.loadImageData(from: url) { _ in }
            }
        }
        return Task()
    }
}

class FeedImageDataLoaderWithFallbackCompositeTests: XCTestCase {
    func test_init_doesNotLoadImageData() {
        let (primaryLoader, fallbackLoader, _) = makeSUT()

        XCTAssertTrue(primaryLoader.loadedURLs.isEmpty, "Expected no loaded urls in the primary loader.")
        XCTAssertTrue(fallbackLoader.loadedURLs.isEmpty, "Expected no loaded urls in the fallback loader.")
    }

    func test_loadImageData_loadsFromPrimaryLoaderFirst() {
        let url = anyURL()
        let (primaryLoader, fallbackLoader, sut) = makeSUT()

        _ = sut.loadImageData(from: url) { _ in }

        XCTAssertEqual(primaryLoader.loadedURLs, [url], "Expected to load url from primary loader first.")
        XCTAssertTrue(fallbackLoader.loadedURLs.isEmpty, "Expected no loaded urls in the fallback loader.")
    }

    func test_loadImageData_loadsFromFallbackOnPrimaryLoaderFailure() {
        let url = anyURL()
        let (primaryLoader, fallbackLoader, sut) = makeSUT()

        _ = sut.loadImageData(from: url) { _ in }

        primaryLoader.complete(with: anyNSError())

        XCTAssertEqual(primaryLoader.loadedURLs, [url], "Expected to load url from primary loader first.")
        XCTAssertEqual(fallbackLoader.loadedURLs, [url], "Expected to load url from fallback loader afterwards.")
    }
}

extension FeedImageDataLoaderWithFallbackCompositeTests {
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (LoaderSpy, LoaderSpy, FeedImageDataLoaderWithFallbackComposite) {
        let primaryLoader = LoaderSpy()
        let fallbackLoader = LoaderSpy()
        let sut = FeedImageDataLoaderWithFallbackComposite(primary: primaryLoader, fallback: fallbackLoader)
        trackForMemoryLeaks(primaryLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (primaryLoader, fallbackLoader, sut)
    }

    final class LoaderSpy: FeedImageDataLoader {
        private final class Task: FeedImageDataLoaderTask {
            func cancel() {}
        }

        private (set) var receivedMessages: [(url: URL, completion: ((LoadResult) -> Void))] = []
        var loadedURLs: [URL] { receivedMessages.map(\.url) }
        private var completions: [(LoadResult) -> Void] { receivedMessages.map(\.completion) }

        func loadImageData(from url: URL, completion: @escaping (LoadResult) -> Void) -> FeedImageDataLoaderTask {
            receivedMessages.append((url, completion))
            return Task()
        }

        func complete(with error: Error, atIndex index: Int = 0) {
            completions[index](.failure(error))
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

    private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}
