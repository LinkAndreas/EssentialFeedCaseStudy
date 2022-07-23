//  Copyright © 2022 Andreas Link. All rights reserved.

import Combine
import EssentialFeed
import EssentialFeediOS

extension CommentsUIIntegrationTests {
    final class LoaderSpy {
        var requests: [PassthroughSubject<[FeedImage], Error>] = []
        var loadCommentsCallCount: Int { requests.count }

        // MARK: - CommentsLoader
        func loadPublisher() -> AnyPublisher<[FeedImage], Error> {
            let publisher = PassthroughSubject<[FeedImage], Error>()
            requests.append(publisher)
            return publisher.eraseToAnyPublisher()
        }

        func completeCommentsLoading(with result: Result<[FeedImage], Error>, atIndex index: Int = 0) {
            switch result {
            case let .success(feed):
                requests[index].send(feed)

            case let .failure(error):
                requests[index].send(completion: .failure(error))
            }
        }

        func completeFeedLoadingWithError(atIndex index: Int = 0) {
            let error = NSError(domain: "an error", code: 0)
            requests[index].send(completion: .failure(error))
        }
    }
}
