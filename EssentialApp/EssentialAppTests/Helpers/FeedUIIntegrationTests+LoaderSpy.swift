//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import EssentialFeediOS

extension FeedUIIntegrationTests {
    final class LoaderSpy: FeedLoader, FeedImageDataLoader {
        var feedRequests: [(FeedLoader.Result) -> Void] = []
        var imageRequests: [(url: URL, completion: (FeedImageDataLoader.LoadResult) -> Void)] = []
        var loadFeedCallCount: Int { feedRequests.count }
        var loadedImageURLs: [URL] { imageRequests.map(\.url) }
        private (set) var cancelledImageURLs: [URL] = []

        private struct TaskSpy: FeedImageDataLoaderTask {
            var onCancel: () -> Void

            func cancel() {
                onCancel()
            }
        }

        // MARK: - FeedLoader
        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            feedRequests.append(completion)
        }

        func completeFeedLoading(with result: FeedLoader.Result, atIndex index: Int = 0) {
            feedRequests[index](result)
        }

        func completeFeedLoadingWithError(atIndex index: Int = 0) {
            let error = NSError(domain: "an error", code: 0)
            feedRequests[index](.failure(error))
        }

        // MARK: - FeedImageDataLoader
        func loadImageData(
            from url: URL,
            completion: @escaping (FeedImageDataLoader.LoadResult) -> Void
        ) -> FeedImageDataLoaderTask {
            let task = TaskSpy(onCancel: { [weak self] in self?.cancelledImageURLs.append(url) })
            imageRequests.append((url, completion))
            return task
        }

        func completeImageLoading(with result: FeedImageDataLoader.LoadResult, atIndex index: Int = 0) {
            imageRequests[index].completion(result)
        }
    }
}
