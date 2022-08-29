//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed

public final class FeedImageDataLoaderWithFallbackComposite: FeedImageDataLoader {
    private let primary: FeedImageDataLoader
    private let fallback: FeedImageDataLoader

    public init(primary: FeedImageDataLoader, fallback: FeedImageDataLoader) {
        self.primary = primary
        self.fallback = fallback
    }

    public func loadImageData(from url: URL) throws -> Data {
        do {
            return try primary.loadImageData(from: url)
        } catch {
            return try fallback.loadImageData(from: url)
        }
    }
}
