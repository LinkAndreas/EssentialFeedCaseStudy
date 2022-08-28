//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed

public final class FeedImageDataLoaderCacheDecorator: FeedImageDataLoader {
    private let decoratee: FeedImageDataLoader
    private let cache: FeedImageDataCache

    public init(decoratee: FeedImageDataLoader, cache: FeedImageDataCache) {
        self.decoratee = decoratee
        self.cache = cache
    }

    public func loadImageData(from url: URL, completion: @escaping (LoadResult) -> Void) -> FeedImageDataLoaderTask {
        return decoratee.loadImageData(from: url) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(imageData):
                self.cache.saveIgnoringResult(imageData, for: url)
                completion(result)

            case .failure:
                completion(result)
            }
        }
    }
}

private extension FeedImageDataCache {
    func saveIgnoringResult(_ imageData: Data, for url: URL) {
        try? save(imageData, for: url)
    }
}
