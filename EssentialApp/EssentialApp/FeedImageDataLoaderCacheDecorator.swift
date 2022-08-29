//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed

public final class FeedImageDataLoaderCacheDecorator: FeedImageDataLoader {
    private let decoratee: FeedImageDataLoader
    private let cache: FeedImageDataCache

    public init(decoratee: FeedImageDataLoader, cache: FeedImageDataCache) {
        self.decoratee = decoratee
        self.cache = cache
    }

    public func loadImageData(from url: URL) throws -> Data {
        let imageData = try decoratee.loadImageData(from: url)
        self.cache.saveIgnoringResult(imageData, for: url)
        return imageData
    }
}

private extension FeedImageDataCache {
    func saveIgnoringResult(_ imageData: Data, for url: URL) {
        try? save(imageData, for: url)
    }
}
