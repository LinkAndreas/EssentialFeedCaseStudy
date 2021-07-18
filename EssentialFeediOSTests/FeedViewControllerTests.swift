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
        let (loader, _) = makeSUT()

        XCTAssertEqual(loader.callCount, 0)
    }

    func test_viewDidLoad_loadsFeed() {
        let (loader, sut) = makeSUT()

        sut.loadViewIfNeeded()

        XCTAssertEqual(loader.callCount, 1)
    }

    // MARK: - Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (loader: LoaderSpy, sut: FeedViewController) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (loader, sut)
    }

    final class LoaderSpy: FeedLoader {
        private (set) var callCount = 0

        func fetchFeed(completion: @escaping (FeedLoader.Result) -> Void) {
            callCount += 1
        }
    }
}
