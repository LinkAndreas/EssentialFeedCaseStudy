//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeediOS
import UIKit

extension ListViewController {
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }

    @discardableResult
    func simulateFeedImageViewVisible(atIndex index: Int = 0) -> FeedImageCell? {
        return feedImageView(atIndex: index) as? FeedImageCell
    }

    @discardableResult
    func simulateFeedImageViewNotVisible(atIndex index: Int = 0) -> FeedImageCell? {
        let view = simulateFeedImageViewVisible(atIndex: index)

        let delegate = tableView.delegate
        delegate?.tableView?(tableView, didEndDisplaying: view!, forRowAt: .init(row: index, section: 0))
        return view
    }

    func simulateFeedImageViewNearVisible(atIndex index: Int = 0) {
        let dataSource = tableView.prefetchDataSource
        let indexPath = IndexPath(row: index, section: 0)
        dataSource?.tableView(tableView, prefetchRowsAt: [indexPath])
    }

    func simulateFeedImageViewNotNearVisible(atIndex index: Int = 0) {
        simulateFeedImageViewNearVisible(atIndex: index)

        let dataSource = tableView.prefetchDataSource
        let indexPath = IndexPath(row: index, section: 0)
        dataSource?.tableView?(tableView, cancelPrefetchingForRowsAt: [indexPath])
    }

    func renderedFeedImageData(atIndex index: Int) -> Data? {
        simulateFeedImageViewVisible(atIndex: index)?.renderedImage
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
        guard numberOfRenderedFeedImageViews() > index else { return nil }

        let dataSource = tableView.dataSource
        let indexPath: IndexPath = .init(row: index, section: 0)
        return dataSource?.tableView(tableView, cellForRowAt: indexPath)
    }

    var errorMessage: String? {
        return errorView?.message
    }

    func simulateErrorMessageButtonTap() {
        errorView?.button.simulateTap()
    }
}
