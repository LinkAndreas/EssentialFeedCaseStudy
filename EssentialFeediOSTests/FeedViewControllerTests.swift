//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import EssentialFeediOS
import XCTest

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

        loaderSpy.completeFeedLoading(with: .success([]), atIndex: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading is completed")

        sut.simulateUserInitiatedFeedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiated load")

        loaderSpy.completeFeedLoading(with: .success([]), atIndex: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user initiated load is complete")
    }

    func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() {
        let image0 = makeImage(description: "a description", location: "a location")
        let image1 = makeImage(description: nil, location: "another location")
        let image2 = makeImage(description: "another description", location: nil)
        let image3 = makeImage(description: nil, location: nil)

        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.numberOfRenderedFeedImageViews(), 0)

        loaderSpy.completeFeedLoading(with: .success([image0]), atIndex: 0)

        XCTAssertEqual(sut.numberOfRenderedFeedImageViews(), 1)

        assertThat(sut, renders: [image0 ])

        sut.simulateUserInitiatedFeedReload()

        loaderSpy.completeFeedLoading(with: .success([image0, image1, image2, image3]), atIndex: 1)
        XCTAssertEqual(sut.numberOfRenderedFeedImageViews(), 4)

        assertThat(sut, renders: [image0, image1, image2, image3])

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

    final class LoaderSpy: FeedLoader {
        var completions: [(FeedLoader.Result) -> Void] = []
        var callCount: Int { completions.count }

        func fetchFeed(completion: @escaping (FeedLoader.Result) -> Void) {
            completions.append(completion)
        }

        func completeFeedLoading(with result: FeedLoader.Result, atIndex index: Int = 0) {
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
