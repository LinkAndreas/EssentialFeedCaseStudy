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

    var errorMessage: String? {
        errorView.message
    }

    func simulateErrorMessageButtonTap() {
        errorView.simulateTap()
    }
}

extension ListViewController {
    func simulateTapOnFeedImage(at index: Int) {
        let delegate = tableView.delegate
        let indexPath = IndexPath(row: index, section: feedImageSection)

        delegate?.tableView?(tableView, didSelectRowAt: indexPath)
    }

    @discardableResult
    func simulateFeedImageViewVisible(atIndex index: Int = 0) -> FeedImageCell? {
        feedImageView(atIndex: index) as? FeedImageCell
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

    func numberOfRenderedFeedImageViews() -> Int {
        tableView.numberOfSections == 0 ? 0 : tableView.numberOfRows(inSection: feedImageSection)
    }

    var feedImageSection: Int { 0 }

    func feedImageView(atIndex index: Int = 0) -> UITableViewCell? {
        guard numberOfRenderedFeedImageViews() > index else { return nil }

        let dataSource = tableView.dataSource
        let indexPath: IndexPath = .init(row: index, section: feedImageSection)
        return dataSource?.tableView(tableView, cellForRowAt: indexPath)
    }
}

extension ListViewController {
    func numberOfRenderedComments() -> Int {
        tableView.numberOfSections == 0 ? 0 : tableView.numberOfRows(inSection: commentsSection)
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

    private func comment(at index: Int) -> ImageCommentCell? {
        guard numberOfRenderedComments() > index else { return nil }

        let dataSource = tableView.dataSource
        let indexPath: IndexPath = .init(row: index, section: commentsSection)
        return dataSource?.tableView(tableView, cellForRowAt: indexPath) as? ImageCommentCell
    }
}
