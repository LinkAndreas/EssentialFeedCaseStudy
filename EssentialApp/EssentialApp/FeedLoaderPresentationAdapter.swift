//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeediOS
import EssentialFeed

class FeedLoaderPresentationAdapter: FeedViewControllerDelegate {
    var presenter: FeedPresenter?

    private let feedLoader: FeedLoader

    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    func didTriggerRefresh() {
        presenter?.didStartLoadingFeed()
        feedLoader.fetchFeed { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .success(feed):
                self.presenter?.didStopLoadingFeed(with: feed)

            case let .failure(error):
                self.presenter?.didStopLoadingFeed(with: error)
            }
        }
    }
}
