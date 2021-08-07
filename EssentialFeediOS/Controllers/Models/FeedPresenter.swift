//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed

protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

final class FeedPresenter {
    typealias Observer<T> = (T) -> Void

    private let feedLoader: FeedLoader

    var loadingView: FeedLoadingView?
    var feedView: FeedView?

    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    func refresh() {
        loadingView?.display(FeedLoadingViewModel(isLoading: true))
        feedLoader.fetchFeed { [weak self] result in
            guard let self = self else { return }

            if let feed = try? result.get() {
                self.feedView?.display(FeedViewModel(feed: feed))
            }

            self.loadingView?.display(FeedLoadingViewModel(isLoading: false))
        }
    }
}
