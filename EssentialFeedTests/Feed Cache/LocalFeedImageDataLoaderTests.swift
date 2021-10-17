//  Copyright © 2021 Andreas Link. All rights reserved.

import XCTest
import EssentialFeed

protocol FeedImageDataStore {
    func retrieve(dataForURL url: URL)
}

final class LocalFeedImageDataLoader {
    private let store: FeedImageDataStore

    init(store: FeedImageDataStore) {
        self.store = store
    }

    func loadImageData(from url: URL, completion: @escaping (Any) -> Void) {
        store.retrieve(dataForURL: url)
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

        var receivedMessages: [Message] = []

        func retrieve(dataForURL url: URL) {
            receivedMessages.append(.retrieve(dataFor: url))
        }
    }
}
