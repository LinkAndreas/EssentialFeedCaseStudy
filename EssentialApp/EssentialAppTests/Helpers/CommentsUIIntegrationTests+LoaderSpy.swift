//  Copyright © 2022 Andreas Link. All rights reserved.

import Combine
import EssentialFeed
import EssentialFeediOS

extension CommentsUIIntegrationTests {
    final class LoaderSpy {
        var requests: [PassthroughSubject<[ImageComment], Error>] = []
        var loadCommentsCallCount: Int { requests.count }

        // MARK: - CommentsLoader
        func loadPublisher() -> AnyPublisher<[ImageComment], Error> {
            let publisher = PassthroughSubject<[ImageComment], Error>()
            requests.append(publisher)
            return publisher.eraseToAnyPublisher()
        }

        func completeCommentsLoading(with result: Result<[ImageComment], Error>, atIndex index: Int = 0) {
            switch result {
            case let .success(comments):
                requests[index].send(comments)

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
