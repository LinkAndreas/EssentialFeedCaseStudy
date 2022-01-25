//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

public final class FeedPresenter {
    private let feedView: FeedView
    private let loadingView: ResourceLoadingView
    private let errorView: ResourceErrorView

    public static var title: String {
        return NSLocalizedString(
            "FEED_VIEW_TITLE",
            tableName: "Feed",
            bundle: Bundle(for: Self.self),
            comment: "Title for the feed view"
        )
    }

    private var feedLoadError: String {
        return NSLocalizedString(
            "GENERIC_CONNECTION_ERROR",
            tableName: "Shared",
            bundle: Bundle(for: FeedPresenter.self),
            comment: "Error message displayed when we can't fetch the feed due to a connection error."
        )
    }

    public init(feedView: FeedView, loadingView: ResourceLoadingView, errorView: ResourceErrorView) {
        self.feedView = feedView
        self.loadingView = loadingView
        self.errorView = errorView
    }

    public func didStartLoadingFeed() {
        errorView.display(.noError)
        loadingView.display(ResourceLoadingViewModel(isLoading: true))
    }

    public func didStopLoadingFeed(with feed: [FeedImage]) {
        feedView.display(FeedViewModel(feed: feed))
        loadingView.display(ResourceLoadingViewModel(isLoading: false))
    }

    public func didStopLoadingFeed(with error: Error) {
        errorView.display(.error(message: feedLoadError))
        loadingView.display(ResourceLoadingViewModel(isLoading: false))
    }

    public static func map(_ feed: [FeedImage]) -> FeedViewModel {
        FeedViewModel(feed: feed)
    }
}
