//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class FeedViewController: UIViewController {
    private var loader: FeedLoader?

    convenience init(loader: FeedLoader) {
        self.init()

        self.loader = loader
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loader?.fetchFeed { _ in }
    }
}

final class FeedViewControllerTests: XCTestCase {
    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        _  = FeedViewController(loader: loader)

        XCTAssertEqual(loader.callCount, 0)
    }

    func test_viewDidLoad_loadsFeed() {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)

        sut.loadViewIfNeeded()

        XCTAssertEqual(loader.callCount, 1)
    }

    // MARK: - Helpers
    final class LoaderSpy: FeedLoader {
        private (set) var callCount = 0

        func fetchFeed(completion: @escaping (FeedLoader.Result) -> Void) {
            callCount += 1
        }
    }
}
