//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed

final class FeedViewModel {
    typealias Observer<T> = (T) -> Void

    enum State {
        case pending
        case loading
    }

    private let feedLoader: FeedLoader

    var onChange: Observer<FeedViewModel>?
    var onFeedChange: Observer<[FeedImage]>?

    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    private (set) var state: State = .pending {
        didSet { onChange?(self) }
    }

    func refresh() {
        state = .loading
        feedLoader.fetchFeed { [weak self] result in
            guard let self = self else { return }

            if let feed = try? result.get() {
                self.onFeedChange?(feed)
            }

            self.state = .pending
        }
    }
}
