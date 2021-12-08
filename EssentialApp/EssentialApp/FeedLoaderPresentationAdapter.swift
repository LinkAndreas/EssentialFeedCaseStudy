//  Copyright © 2021 Andreas Link. All rights reserved.

import Combine
import EssentialFeediOS
import EssentialFeed

class FeedLoaderPresentationAdapter: FeedViewControllerDelegate {
    var presenter: FeedPresenter?

    private let feedLoader: () -> FeedLoader.Publisher
    private var cancellable: AnyCancellable?

    init(feedLoader: @escaping () -> FeedLoader.Publisher) {
        self.feedLoader = feedLoader
    }

    func didTriggerRefresh() {
        presenter?.didStartLoadingFeed()
        cancellable = feedLoader().sink(
            receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished: break

                case let .failure(error):
                    self?.presenter?.didStopLoadingFeed(with: error)
                }
            },
            receiveValue: { [weak self] feed in
                self?.presenter?.didStopLoadingFeed(with: feed)
            }
        )
    }
}
