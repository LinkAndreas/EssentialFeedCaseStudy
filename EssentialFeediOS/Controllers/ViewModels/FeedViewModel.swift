//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed

final class FeedViewModel {
    typealias Observer<T> = (T) -> Void

    private let feedLoader: FeedLoader

    var onIsLoadingChanged: Observer<Bool>?
    var onFeedChanged: Observer<[FeedImage]>?

    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    func refresh() {
        onIsLoadingChanged?(true)
        feedLoader.fetchFeed { [weak self] result in
            guard let self = self else { return }

            if let feed = try? result.get() {
                self.onFeedChanged?(feed)
            }

            self.onIsLoadingChanged?(false)
        }
    }
}
