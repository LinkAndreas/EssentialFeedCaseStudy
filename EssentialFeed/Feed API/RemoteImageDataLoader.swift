//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public final class RemoteImageDataLoader: FeedImageDataLoader {
    public enum Error: Swift.Error {
        case invalidData
    }

    public typealias Result = Swift.Result<Data, Swift.Error>

    private class HTTPTaskWrapper: FeedImageDataLoaderTask {
        var wrapped: HTTPClientTask?

        private var completion: ((Result) -> Void)?

        init(completion: @escaping (Result) -> Void) {
            self.completion = completion
        }

        func cancel() {
            preventFurtherCompletions()
            wrapped?.cancel()
        }

        func complete(with result: Result) {
            completion?(result)
        }

        private func preventFurtherCompletions() {
            completion = nil
        }
    }

    private let client: HTTPClient

    public init(client: HTTPClient) {
        self.client = client
    }

    @discardableResult
    public func loadImageData(from url: URL, completion: @escaping (Result) -> Void) -> FeedImageDataLoaderTask  {
        let task = HTTPTaskWrapper(completion: completion)
        task.wrapped = client.load(from: url) { [weak self] result in
            guard self != nil else { return }

            switch result {
            case let .success((data, response)) where response.statusCode == 200 && !data.isEmpty:
                task.complete(with: .success(data))

            case let .success((data, response)) where response.statusCode == 200 && data.isEmpty:
                task.complete(with: .failure(Error.invalidData))

            case let .success((_, response)) where response.statusCode != 200:
                task.complete(with: .failure(Error.invalidData))

            case let .failure(error):
                task.complete(with: .failure(error))

            default:
                break
            }
        }

        return task
    }
}
