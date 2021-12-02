//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed

public final class FeedImageDataLoaderWithFallbackComposite: FeedImageDataLoader {
    private final class TaskWrapper: FeedImageDataLoaderTask {
        var wrapped: FeedImageDataLoaderTask?

        func cancel() {
            wrapped?.cancel()
        }
    }

    private let primary: FeedImageDataLoader
    private let fallback: FeedImageDataLoader

    public init(primary: FeedImageDataLoader, fallback: FeedImageDataLoader) {
        self.primary = primary
        self.fallback = fallback
    }

    public func loadImageData(from url: URL, completion: @escaping (LoadResult) -> Void) -> FeedImageDataLoaderTask {
        let task = TaskWrapper()
        task.wrapped = primary.loadImageData(from: url) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                completion(result)

            case .failure:
                task.wrapped = self.fallback.loadImageData(from: url, completion: completion)
            }
        }

        return task
    }
}
