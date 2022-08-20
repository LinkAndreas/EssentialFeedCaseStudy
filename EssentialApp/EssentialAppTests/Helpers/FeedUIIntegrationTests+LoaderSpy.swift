//  Copyright © 2021 Andreas Link. All rights reserved.

import Combine
import EssentialFeed
import EssentialFeediOS

extension FeedUIIntegrationTests {
    final class LoaderSpy: FeedImageDataLoader {
        var feedRequests: [PassthroughSubject<Paginated<FeedImage>, Error>] = []
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
        func loadPublisher() -> AnyPublisher<Paginated<FeedImage>, Error> {
            let publisher = PassthroughSubject<Paginated<FeedImage>, Error>()
            feedRequests.append(publisher)
            return publisher.eraseToAnyPublisher()
        }

        func completeFeedLoading(with result: Result<[FeedImage], Error>, atIndex index: Int = 0) {
            switch result {
            case let .success(feed):
                feedRequests[index].send(Paginated(items: feed))

            case let .failure(error):
                feedRequests[index].send(completion: .failure(error))
            }
        }

        func completeFeedLoadingWithError(atIndex index: Int = 0) {
            let error = NSError(domain: "an error", code: 0)
            feedRequests[index].send(completion: .failure(error))
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
