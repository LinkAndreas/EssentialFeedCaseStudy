//  Copyright © 2021 Andreas Link. All rights reserved.

import Combine
import EssentialFeed
import EssentialFeediOS

extension FeedUIIntegrationTests {
    final class LoaderSpy: FeedImageDataLoader {
        var feedRequests: [PassthroughSubject<Paginated<FeedImage>, Error>] = []
        var loadMoreRequests: [PassthroughSubject<Paginated<FeedImage>, Error>] = []
        var imageRequests: [(url: URL, completion: (FeedImageDataLoader.LoadResult) -> Void)] = []

        var loadFeedCallCount: Int { feedRequests.count }
        var loadMoreCallCount: Int { loadMoreRequests.count }
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

        func completeFeedLoading(with feed: [FeedImage] = [], at index: Int = 0) {
            feedRequests[index].send(
                Paginated(
                    items: feed,
                    loadMorePublisher: { [weak self] in
                        let publisher = PassthroughSubject<Paginated<FeedImage>, Error>()
                        self?.loadMoreRequests.append(publisher)
                        return publisher.eraseToAnyPublisher()
                    }
                )
            )
        }

        func completeFeedLoadingWithError(
            _ error: Error = NSError(domain: "an error", code: 0),
            at index: Int = 0
        ) {
            feedRequests[index].send(completion: .failure(error))
        }

        func completeLoadMore(with feed: [FeedImage] = [], lastPage: Bool = false, at index: Int = 0) {
            loadMoreRequests[index].send(
                Paginated(
                    items: feed,
                    loadMorePublisher: lastPage ? nil : { [weak self] in
                        let publisher = PassthroughSubject<Paginated<FeedImage>, Error>()
                        self?.loadMoreRequests.append(publisher)
                        return publisher.eraseToAnyPublisher()
                    }
                )
            )
        }

        func completeLoadMoreWithError(
            _ error: Error = NSError(domain: "an error", code: 0),
            at index: Int = 0
        ) {
            loadMoreRequests[index].send(completion: .failure(error))
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

        func completeImageLoading(with result: FeedImageDataLoader.LoadResult, at index: Int = 0) {
            imageRequests[index].completion(result)
        }
    }
}
