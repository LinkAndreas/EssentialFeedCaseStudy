//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import EssentialFeediOS
import XCTest

final class FeedViewControllerTests: XCTestCase {
    func test_loadFeedActions_requestsFeedFromLoader() {
        let (loaderSpy, sut) = makeSUT()

        XCTAssertEqual(loaderSpy.loadFeedCallCount, 0, "Expected no loading requests before view is loaded")

        sut.loadViewIfNeeded()
        XCTAssertEqual(loaderSpy.loadFeedCallCount, 1, "Expected a loading request once the view is loaded")

        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loaderSpy.loadFeedCallCount, 2, "Expected another load request once user initiated the load")

        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loaderSpy.loadFeedCallCount, 3, "Expected a third load request once user initiated another load")
    }

    func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")

        loaderSpy.completeFeedLoading(with: .success([]), atIndex: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading is completed")

        sut.simulateUserInitiatedFeedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiated load")

        loaderSpy.completeFeedLoading(with: .failure(anyNSError()), atIndex: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user initiated load failed")
    }

    func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() {
        let image0 = makeImage(description: "a description", location: "a location")
        let image1 = makeImage(description: nil, location: "another location")
        let image2 = makeImage(description: "another description", location: nil)
        let image3 = makeImage(description: nil, location: nil)

        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()

        assertThat(sut, renders: [])

        loaderSpy.completeFeedLoading(with: .success([image0]))

        assertThat(sut, renders: [image0])

        sut.simulateUserInitiatedFeedReload()

        loaderSpy.completeFeedLoading(with: .success([image0, image1, image2, image3]), atIndex: 1)

        assertThat(sut, renders: [image0, image1, image2, image3])
    }

    func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let image0 = makeImage(description: "a description", location: "a location")
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()

        loaderSpy.completeFeedLoading(with: .success([image0]))

        assertThat(sut, renders: [image0])

        sut.simulateUserInitiatedFeedReload()

        loaderSpy.completeFeedLoading(with: .failure(anyNSError()), atIndex: 1)

        assertThat(sut, renders: [image0])
    }

    func test_feedImageView_loadsImageURLWhenVisible() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)

        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: .success([image0, image1]))

        XCTAssertEqual(loaderSpy.loadedImageURLs, [], "Expected no image URL requests until views become visible")

        sut.simulateFeedImageViewVisible(atIndex: 0)

        XCTAssertEqual(loaderSpy.loadedImageURLs, [image0.url], "Expected first image URL request once first view becomes visible")

        sut.simulateFeedImageViewVisible(atIndex: 1)

        XCTAssertEqual(loaderSpy.loadedImageURLs, [image0.url, image1.url], "Expected second image URL request once second view becomes visible")
    }

    func test_feedImageView_cancelsFeedImageLoadingWhenNotVisibleAnymore() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-0.com")!)

        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: .success([image0, image1]))

        XCTAssertEqual(loaderSpy.cancelledImageURLs, [], "Expected no image URL requests until views become visible")

        sut.simulateFeedImageViewNotVisible(atIndex: 0)

        XCTAssertEqual(loaderSpy.cancelledImageURLs, [image0.url], "Expected on cancelled image URL request once first view is not visible anymore")

        sut.simulateFeedImageViewNotVisible(atIndex: 1)

        XCTAssertEqual(loaderSpy.cancelledImageURLs, [image0.url, image1.url], "Expected two cancelled image URL requests once second view is not visible anymore")
    }

    // MARK: - Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (loaderSpy: LoaderSpy, sut: FeedViewController) {
        let loaderSpy = LoaderSpy()
        let sut = FeedViewController(loader: loaderSpy, imageLoader: loaderSpy)
        trackForMemoryLeaks(loaderSpy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (loaderSpy, sut)
    }

    private func makeImage(
        description: String? = "any description",
        location: String? = nil,
        url: URL = .init(string: "http://any-url.com")!
    ) -> FeedImage {
        return .init(id: UUID(), description: description, location: location, url: url)
    }

    private func assertThat(
        _ sut: FeedViewController,
        renders models: [FeedImage],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let nmberOfRenderedFeedImageViews: Int = sut.numberOfRenderedFeedImageViews()

        XCTAssertEqual(
            nmberOfRenderedFeedImageViews,
            models.count,
            "Expected \(models.count) images, got \(nmberOfRenderedFeedImageViews)",
            file: file,
            line: line
        )

        for (index, model) in models.enumerated() {
            assertThat(sut, hasViewConfiguredFor: model, atIndex: index, file: file, line: line)
        }
    }

    private func assertThat(
        _ sut: FeedViewController,
        hasViewConfiguredFor model: FeedImage,
        atIndex index: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = sut.feedImageView(atIndex: index)

        guard let cell = view as? FeedImageCell else {
            XCTFail("Expected \(FeedImageCell.self) instance, got \(String(describing: view))", file: file, line: line)
            return
        }

        let shouldLocationBeVisible: Bool = model.location != nil
        XCTAssertNotNil(view, file: file, line: line)
        XCTAssertEqual(
            cell.isShowingLocation,
            shouldLocationBeVisible,
            "Expected isShowingLocation to be \(shouldLocationBeVisible) for image view at index \(index)",
            file: file,
            line: line
        )
        XCTAssertEqual(
            cell.locationText,
            model.location,
            "Expected locationText to be \(String(describing: model.location)) for image view at index \(index)",
            file: file,
            line: line
        )
        XCTAssertEqual(
            cell.descriptionText,
            model.description,
            "Expected descriptionText to be \(String(describing: model.description)) for image view at index \(index)",
            file: file,
            line: line
        )
    }

    final class LoaderSpy: FeedLoader, FeedImageDataLoader {
        var feedRequests: [(FeedLoader.Result) -> Void] = []
        var loadFeedCallCount: Int { feedRequests.count }
        private (set) var loadedImageURLs: [URL] = []
        private (set) var cancelledImageURLs: [URL] = []

        // MARK: - FeedLoader
        func fetchFeed(completion: @escaping (FeedLoader.Result) -> Void) {
            feedRequests.append(completion)
        }

        func completeFeedLoading(with result: FeedLoader.Result, atIndex index: Int = 0) {
            feedRequests[index](result)
        }

        // MARK: - FeedImageDataLoader
        func loadImageData(from url: URL) {
            loadedImageURLs.append(url)
        }

        func cancelImageDataLoad(from url: URL) {
            cancelledImageURLs.append(url)
        }
    }
}

private extension FeedViewController {
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }

    @discardableResult
    func simulateFeedImageViewVisible(atIndex index: Int) -> FeedImageCell? {
        return feedImageView(atIndex: index) as? FeedImageCell
    }

    func simulateFeedImageViewNotVisible(atIndex index: Int) {
        let view = simulateFeedImageViewVisible(atIndex: index)

        let delegate = tableView.delegate
        delegate?.tableView?(tableView, didEndDisplaying: view!, forRowAt: .init(row: index, section: 0))
    }

    var isShowingLoadingIndicator: Bool {
        return refreshControl?.isRefreshing == true
    }

    func numberOfRenderedFeedImageViews() -> Int {
        return tableView.numberOfRows(inSection: feedImageSection)
    }

    var feedImageSection: Int {
        0
    }

    func feedImageView(atIndex index: Int = 0) -> UITableViewCell? {
        let dataSource = tableView.dataSource
        let indexPath: IndexPath = .init(row: index, section: 0)
        return dataSource?.tableView(tableView, cellForRowAt: indexPath)
    }
}

extension FeedImageCell {
    var locationText: String? {
        locationLabel.text
    }

    var descriptionText: String? {
        descriptionLabel.text
    }

    var isShowingLocation: Bool {
        !locationContainer.isHidden
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
