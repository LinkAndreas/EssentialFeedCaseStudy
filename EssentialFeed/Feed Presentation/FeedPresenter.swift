//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

public protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

public protocol FeedErrorView {
    func display(_ viewModel: FeedErrorViewModel)
}

public final class FeedPresenter {
    private let feedView: FeedView
    private let feedLoadingView: FeedLoadingView
    private let feedErrorView: FeedErrorView

    public static var title: String {
        return NSLocalizedString(
            "FEED_VIEW_TITLE",
            tableName: "Feed",
            bundle: Bundle(for: FeedPresenter.self),
            comment: "Title for the feed view"
        )
    }

    private var feedLoadError: String {
        return NSLocalizedString(
            "FEED_VIEW_CONNECTION_ERROR",
            tableName: "Feed",
            bundle: Bundle(for: FeedPresenter.self),
            comment: "Error message displayed when we can't fetch the feed due to a connection error."
        )
    }

    public init(feedView: FeedView, feedLoadingView: FeedLoadingView, feedErrorView: FeedErrorView) {
        self.feedView = feedView
        self.feedLoadingView = feedLoadingView
        self.feedErrorView = feedErrorView
    }

    public func didStartLoadingFeed() {
        feedErrorView.display(.noError)
        feedLoadingView.display(FeedLoadingViewModel(isLoading: true))
    }

    public func didStopLoadingFeed(with feed: [FeedImage]) {
        feedView.display(FeedViewModel(feed: feed))
        feedLoadingView.display(FeedLoadingViewModel(isLoading: false))
    }

    public func didStopLoadingFeed(with error: Error) {
        feedErrorView.display(.error(message: feedLoadError))
        feedLoadingView.display(FeedLoadingViewModel(isLoading: false))
    }
}
