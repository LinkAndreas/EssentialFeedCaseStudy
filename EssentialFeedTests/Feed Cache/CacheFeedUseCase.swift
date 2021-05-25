//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

class LocalFeedLoader {
    private let store: FeedStore

    init(store: FeedStore) {
        self.store = store
    }

    func save(items: [FeedItem]) {
        store.deleteCachedFeed()
    }
}

class FeedStore {
    var deleteCacheCallCount: Int = 0
    var insertCallCount: Int = 0

    func deleteCachedFeed() {
        deleteCacheCallCount += 1
    }

    func completeDeletion(with error: Error, atIndex index: Int = 0) {

    }
}

class CacheFeedUseCase: XCTestCase {
    func test_init_doesNotDeleteFeedOnCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.deleteCacheCallCount, 0)
    }

    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()

        sut.save(items: [uniqueItem(), uniqueItem()])

        XCTAssertEqual(store.deleteCacheCallCount, 1)
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let items: [FeedItem] = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()

        sut.save(items: items)
        store.completeDeletion(with: anyError(), atIndex: 0)

        XCTAssertEqual(store.insertCallCount, 0)
    }

    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (LocalFeedLoader, FeedStore) {
        let store: FeedStore = .init()
        let sut: LocalFeedLoader = .init(store: store)

        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (sut, store)
    }

    private func uniqueItem() -> FeedItem {
        return .init(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }

    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }

    private func anyError() -> Error {
        return NSError(domain: "any domain", code: 42, userInfo: nil)
    }
}


