//  Copyright © 2021 Andreas Link. All rights reserved.

import Combine
import EssentialFeediOS
import EssentialFeed

class FeedLoaderPresentationAdapter: FeedViewControllerDelegate {
    var presenter: LoadResourcePresenter<[FeedImage], FeedViewAdapter>?

    private let feedLoader: () -> AnyPublisher<[FeedImage], Error>
    private var cancellable: AnyCancellable?

    init(feedLoader: @escaping () -> AnyPublisher<[FeedImage], Error>) {
        self.feedLoader = feedLoader
    }

    func didTriggerRefresh() {
        presenter?.didStartLoading()
        cancellable = feedLoader().sink(
            receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished: break

                case let .failure(error):
                    self?.presenter?.didStopLoading(with: error)
                }
            },
            receiveValue: { [weak self] feed in
                self?.presenter?.didStopLoading(with: feed)
            }
        )
    }
}
