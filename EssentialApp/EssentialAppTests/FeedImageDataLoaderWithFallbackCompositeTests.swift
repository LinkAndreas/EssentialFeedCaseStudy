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
    private final class TaskWrapper: FeedImageDataLoaderTask {
        var wrapped: FeedImageDataLoaderTask?

        func cancel() {
            wrapped?.cancel()
        }
    }

    private let primary: FeedImageDataLoader
    private let fallback: FeedImageDataLoader

    init(primary: FeedImageDataLoader, fallback: FeedImageDataLoader) {
        self.primary = primary
        self.fallback = fallback
    }

    func loadImageData(from url: URL, completion: @escaping (LoadResult) -> Void) -> FeedImageDataLoaderTask {
        let task = TaskWrapper()
        task.wrapped = primary.loadImageData(from: url) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                completion(result)

            case .failure:
                task.wrapped = self.fallback.loadImageData(from: url, completion: completion)
            }
        }

        return task
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

    func test_cancelLoadImageData_cancelsPrimaryLoaderTask() {
        let url = anyURL()
        let (primaryLoader, fallbackLoader, sut) = makeSUT()

        let task = sut.loadImageData(from: url) { _ in }
        task.cancel()

        XCTAssertEqual(primaryLoader.cancelledURLs, [url], "Expected to cancel URL loading from primary loader.")
        XCTAssertTrue(fallbackLoader.cancelledURLs.isEmpty, "Expected no cancelled URLs in the fallback loader.")
    }

    func test_cancelLoadImageData_cancelsFallbackLoaderTaskAfterPrimaryLoaderFailure() {
        let url = anyURL()
        let (primaryLoader, fallbackLoader, sut) = makeSUT()

        let task = sut.loadImageData(from: url) { _ in }
        primaryLoader.complete(with: anyNSError())
        task.cancel()

        XCTAssertTrue(primaryLoader.cancelledURLs.isEmpty, "Expected to cancel URL loading from primary loader.")
        XCTAssertEqual(fallbackLoader.cancelledURLs, [url], "Expected to cancel URL loading from fallback loader.")
    }

    func test_loadImageData_deliversPrimaryDataOnPrimaryLoaderSuccess() {
        let primaryData = anyData()
        let (primaryLoader, _, sut) = makeSUT()

        expect(sut, toCompleteWith: .success(primaryData), when: {
            primaryLoader.complete(with: primaryData)
        })
    }

    func test_loadImageData_deliversFallbackDataOnFallbackLoaderSuccess() {
        let fallbackData = anyData()
        let (primaryLoader, fallbackLoader, sut) = makeSUT()

        expect(sut, toCompleteWith: .success(fallbackData), when: {
            primaryLoader.complete(with: anyNSError())
            fallbackLoader.complete(with: fallbackData)
        })
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
            private let callback: () -> Void

            init(callback: @escaping () -> Void) {
                self.callback = callback
            }

            func cancel() {
                callback()
            }
        }

        private (set) var receivedMessages: [(url: URL, completion: ((LoadResult) -> Void))] = []
        var loadedURLs: [URL] { receivedMessages.map(\.url) }
        var cancelledURLs: [URL] = []
        private var completions: [(LoadResult) -> Void] { receivedMessages.map(\.completion) }

        func loadImageData(from url: URL, completion: @escaping (LoadResult) -> Void) -> FeedImageDataLoaderTask {
            receivedMessages.append((url, completion))
            return Task { [weak self] in
                self?.cancelledURLs.append(url)
            }
        }

        func complete(with data: Data, atIndex index: Int = 0) {
            completions[index](.success(data))
        }

        func complete(with error: Error, atIndex index: Int = 0) {
            completions[index](.failure(error))
        }
    }

    private func expect(
        _ sut: FeedImageDataLoaderWithFallbackComposite,
        toCompleteWith expectedResult: FeedImageDataLoader.LoadResult,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let url = anyURL()
        let expectation = expectation(description: "Wait for result.")

        _ = sut.loadImageData(from: url) { receivedResult in
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

        action()

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
