//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeediOS
import UIKit

extension ListViewController {
    public override func loadViewIfNeeded() {
        super.loadViewIfNeeded()

        tableView.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
    }

    func simulateUserInitiatedReload() {
        refreshControl?.simulatePullToRefresh()
    }

    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing == true
    }

    var isShowingLoadingMoreIndicator: Bool {
        loadMoreView()?.isLoading == true
    }

    var errorMessage: String? {
        errorView.message
    }

    func simulateErrorMessageButtonTap() {
        errorView.simulateTap()
    }

    func cell(row: Int, section: Int) -> UITableViewCell? {
        guard
            let dataSource = tableView.dataSource,
            dataSource.numberOfSections?(in: tableView) ?? 0 > section,
            dataSource.tableView(tableView, numberOfRowsInSection: section) > row
        else { return nil }

        let indexPath = IndexPath(row: row, section: section)
        return dataSource.tableView(tableView, cellForRowAt: indexPath)
    }
}

extension ListViewController {
    func simulateTapOnFeedImage(at index: Int) {
        let delegate = tableView.delegate
        let indexPath = IndexPath(row: index, section: feedImageSection)

        delegate?.tableView?(tableView, didSelectRowAt: indexPath)
    }

    func simulateLoadMoreFeedAction() {
        guard let view = loadMoreView() else { return }

        let delegate = tableView.delegate
        let indexPath = IndexPath(row: 0, section: feedLoadMoreSection)
        delegate?.tableView?(tableView, willDisplay: view, forRowAt: indexPath)
    }

    @discardableResult
    func simulateFeedImageViewVisible(at index: Int = 0) -> FeedImageCell? {
        feedImageView(at: index)
    }

    @discardableResult
    func simulateFeedImageViewNotVisible(at index: Int = 0) -> FeedImageCell? {
        let view = simulateFeedImageViewVisible(at: index)

        let delegate = tableView.delegate
        delegate?.tableView?(tableView, didEndDisplaying: view!, forRowAt: .init(row: index, section: 0))
        return view
    }

    func simulateFeedImageViewNearVisible(at index: Int = 0) {
        let dataSource = tableView.prefetchDataSource
        let indexPath = IndexPath(row: index, section: 0)
        dataSource?.tableView(tableView, prefetchRowsAt: [indexPath])
    }

    func simulateFeedImageViewNotNearVisible(at index: Int = 0) {
        simulateFeedImageViewNearVisible(at: index)

        let dataSource = tableView.prefetchDataSource
        let indexPath = IndexPath(row: index, section: 0)
        dataSource?.tableView?(tableView, cancelPrefetchingForRowsAt: [indexPath])
    }

    func renderedFeedImageData(at index: Int) -> Data? {
        simulateFeedImageViewVisible(at: index)?.renderedImage
    }

    func numberOfRenderedFeedImageViews() -> Int {
        tableView.numberOfSections > feedImageSection ? tableView.numberOfRows(inSection: feedImageSection) : 0
    }

    func numberOfRenderedLoadMoreViews() -> Int {
        tableView.numberOfSections > feedLoadMoreSection ? tableView.numberOfRows(inSection: feedLoadMoreSection) : 0
    }

    func feedImageView(at row: Int = 0) -> FeedImageCell? {
        return cell(row: row, section: feedImageSection) as? FeedImageCell
    }

    func loadMoreView(at row: Int = 0) -> LoadMoreCell? {
        return cell(row: row, section: feedLoadMoreSection) as? LoadMoreCell
    }

    var feedImageSection: Int { 0 }
    var feedLoadMoreSection: Int { 1 }
}

extension ListViewController {
    func numberOfRenderedComments() -> Int {
        tableView.numberOfSections > commentsSection ? tableView.numberOfRows(inSection: commentsSection) : 0
    }

    var commentsSection: Int { 0 }

    func commentMessage(at index: Int) -> String? {
        return comment(at: index)?.messageLabel.text
    }

    func commentDate(at index: Int) -> String? {
        return comment(at: index)?.dateLabel.text
    }

    func commentUsername(at index: Int) -> String? {
        return comment(at: index)?.usernameLabel.text
    }

    private func comment(at index: Int = 0) -> ImageCommentCell? {
        return cell(row: index, section: commentsSection) as? ImageCommentCell
    }
}
