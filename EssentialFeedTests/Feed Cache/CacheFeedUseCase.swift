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

    func deleteCachedFeed() {
        deleteCacheCallCount += 1
    }
}

class CacheFeedUseCase: XCTestCase {
    func test_init_doesNotDeleteFeedOnCreation() {
        let store: FeedStore = .init()
        let _: LocalFeedLoader = .init(store: store)

        XCTAssertEqual(store.deleteCacheCallCount, 0)
    }

    func test_save_requestsCacheDeletion() {
        let store: FeedStore = .init()
        let sut: LocalFeedLoader = .init(store: store)

        sut.save(items: [uniqueItem(), uniqueItem()])

        XCTAssertEqual(store.deleteCacheCallCount, 1)
    }

    private func uniqueItem() -> FeedItem {
        return .init(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }

    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
}


