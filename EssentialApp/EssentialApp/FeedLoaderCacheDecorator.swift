//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed

public final class FeedLoaderCacheDecorator: FeedLoader {
    private let decoratee: FeedLoader
    private let cache: FeedCache

    public init(decoratee: FeedLoader, cache: FeedCache) {
        self.decoratee = decoratee
        self.cache = cache
    }

    public func fetchFeed(completion: @escaping (FeedLoader.Result) -> Void) {
        decoratee.fetchFeed { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(feed):
                self.cache.saveIgnoringResult(feed)
                completion(result)

            case .failure:
                completion(result)
            }
        }
    }
}

private extension FeedCache {
    func saveIgnoringResult(_ feed: [FeedImage]) {
        save(feed) { _ in }
    }
}
