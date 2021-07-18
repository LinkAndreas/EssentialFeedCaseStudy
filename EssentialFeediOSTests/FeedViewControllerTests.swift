//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class FeedViewController {
    private let loader: FeedLoader

    init(loader: FeedLoader) {
        self.loader = loader
    }
}

final class FeedViewControllerTests: XCTestCase {
    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        _  = FeedViewController(loader: loader)

        XCTAssertEqual(loader.callCount, 0)
    }

    // MARK: - Helpers
    final class LoaderSpy: FeedLoader {
        private (set) var callCount = 0

        func fetchFeed(completion: @escaping (FeedLoader.Result) -> Void) {
            callCount += 1
        }
    }
}
