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
    func test_init_doesNotLoadFeed() {
        let (loaderSpy, _) = makeSUT()

        XCTAssertEqual(loaderSpy.callCount, 0)
    }

    func test_viewDidLoad_loadsFeed() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()

        XCTAssertEqual(loaderSpy.callCount, 1)
    }

    func test_pullToRefresh_loadsFeed() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        sut.refreshControl?.simulatePullToRefresh()
        sut.refreshControl?.simulatePullToRefresh()

        XCTAssertEqual(loaderSpy.callCount, 3)
    }

    func test_viewDidLoad_showsLoadingIndicator() {
        let (_, sut) = makeSUT()

        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
    }

    func test_viewDidLoad_hidesLoadingIndicatorOnLoaderCompletion() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.complete(with: .success([]))

        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
    }

    func test_pullToRefresh_showsLoadingIndicator() {
        let (_, sut) = makeSUT()

        sut.refreshControl?.simulatePullToRefresh()

        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
    }

    func test_pullToRefresh_hidesLoadingIndicatorOnLoaderCompletion() {
        let (loaderSpy, sut) = makeSUT()

        sut.refreshControl?.simulatePullToRefresh()
        loaderSpy.complete(with: .success([]))

        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
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

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                (target as NSObject).perform(Selector(action))
            }
        }
    }
}
