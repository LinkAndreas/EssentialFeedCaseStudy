//  Copyright © 2021 Andreas Link. All rights reserved.

import XCTest

class LocalFeedLoader {
    init(store: FeedStore) { }
}

class FeedStore {
    var deleteCacheCallCount: Int = 0
}

class CacheFeedUseCase: XCTestCase {
    func test_store_doesNotDeleteFeedOnInitialization() {
        let store: FeedStore = .init()
        let _: LocalFeedLoader = .init(store: store)


        XCTAssertEqual(store.deleteCacheCallCount, 0)
    }
}

