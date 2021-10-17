//  Copyright © 2021 Andreas Link. All rights reserved.

import XCTest
import EssentialFeed

protocol FeedImageDataStore {
    typealias Result = Swift.Result<Data, Error>

    func retrieve(dataForURL url: URL, completion: @escaping (Result) -> Void)
}

final class LocalFeedImageDataLoader {
    private let store: FeedImageDataStore

    init(store: FeedImageDataStore) {
        self.store = store
    }

    func loadImageData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        store.retrieve(dataForURL: url) { result in
            switch result {
            case let .success(data):
                completion(.success(data))

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

final class LocalFeedImageDataLoaderTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (spy, _) = makeSUT()

        XCTAssertTrue(spy.receivedMessages.isEmpty)
    }

    func test_loadImageData_requestsStoreDataForURL() {
        let url = anyURL()
        let (spy, sut) = makeSUT()

        sut.loadImageData(from: url) { _ in }

        XCTAssertEqual(spy.receivedMessages, [.retrieve(dataFor: url)])
    }

    func test_loadImageData_deliversErrorOnStoreError() {
        let error = anyNSError()
        let url = anyURL()
        let (spy, sut) = makeSUT()

        let expectation = expectation(description: "Wait for load result.")
        sut.loadImageData(from: url) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(receivedError, error, "Expected to receive \(error), but received \(receivedError) instead.")
                expectation.fulfill()

            default:
                XCTFail("Expected to receive error on store error.")
            }
        }

        spy.completeDataRetrieval(with: error)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(spy.receivedMessages, [.retrieve(dataFor: url)])
    }


    // MARK: - Helper
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (StoreSpy, LocalFeedImageDataLoader) {
        let store = StoreSpy()
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (store, sut)
    }

    private class StoreSpy: FeedImageDataStore {
        enum Message: Equatable {
            case retrieve(dataFor: URL)
        }

        private (set) var receivedMessages: [Message] = []
        private var completions: [(FeedImageDataStore.Result) -> Void] = []

        func retrieve(dataForURL url: URL, completion: @escaping (FeedImageDataStore.Result) -> Void) {
            receivedMessages.append(.retrieve(dataFor: url))
            completions.append(completion)
        }

        func completeDataRetrieval(with error: Error, atIndex index: Int = 0) {
            completions[index](.failure(error))
        }
    }
}
