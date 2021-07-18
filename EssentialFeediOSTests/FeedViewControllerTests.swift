//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class FeedViewController: UITableViewController {
    private var loader: FeedLoader?

    convenience init(loader: FeedLoader) {
        self.init()

        self.loader = loader
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load ), for: .valueChanged)
        load()
    }

    @objc
    private func load() {
        refreshControl?.beginRefreshing()
        loader?.fetchFeed { [weak self] _ in
            guard let self = self else { return }

            self.refreshControl?.endRefreshing()
        }
    }
}

final class FeedViewControllerTests: XCTestCase {
    func test_loadFeedActions_requestsFeedFromLoader() {
        let (loaderSpy, sut) = makeSUT()

        XCTAssertEqual(loaderSpy.callCount, 0, "Expected no loading requests before view is loaded")

        sut.loadViewIfNeeded()
        XCTAssertEqual(loaderSpy.callCount, 1, "Expected a loading request once the view is loaded")

        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loaderSpy.callCount, 2, "Expected another load request once user initiated the load")

        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loaderSpy.callCount, 3, "Expected a third load request once user initiated another load")
    }

    func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")

        loaderSpy.complete(with: .success([]), atIndex: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading is completed")

        sut.simulateUserInitiatedFeedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiated load")

        loaderSpy.complete(with: .success([]), atIndex: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user initiated load is complete")
    }

    // MARK: - Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (loaderSpy: LoaderSpy, sut: FeedViewController) {
        let loaderSpy = LoaderSpy()
        let sut = FeedViewController(loader: loaderSpy)
        trackForMemoryLeaks(loaderSpy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (loaderSpy, sut)
    }

    final class LoaderSpy: FeedLoader {
        var completions: [(FeedLoader.Result) -> Void] = []
        var callCount: Int { completions.count }

        func fetchFeed(completion: @escaping (FeedLoader.Result) -> Void) {
            completions.append(completion)
        }

        func complete(with result: FeedLoader.Result, atIndex index: Int = 0) {
            completions[index](result)
        }
    }
}

private extension FeedViewController {
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }

    var isShowingLoadingIndicator: Bool {
        return refreshControl?.isRefreshing == true
    }
}

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                (target as NSObject).perform(Selector(action))
            }
        }
    }
}
