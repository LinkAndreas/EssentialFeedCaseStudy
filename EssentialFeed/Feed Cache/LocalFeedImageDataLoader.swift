//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public final class LocalFeedImageDataLoader {
    public enum Error: Swift.Error {
        case failed
        case notFound
    }

    public typealias Result = Swift.Result<Data?, Swift.Error>
    public typealias InsertionResult = Swift.Result<Void, Swift.Error>

    private final class Task: FeedImageDataLoaderTask {
        private var completion: ((FeedImageDataLoader.Result) -> Void)?

        init(completion: @escaping (FeedImageDataLoader.Result) -> Void) {
            self.completion = completion
        }

        func complete(with result: FeedImageDataLoader.Result) {
            completion?(result)
        }

        func cancel() {
            preventFurtherCompletions()
        }

        private func preventFurtherCompletions() {
            completion = nil
        }
    }

    private let store: FeedImageDataStore

    public init(store: FeedImageDataStore) {
        self.store = store
    }

    public func loadImageData(from url: URL, completion: @escaping (Result) -> Void) -> FeedImageDataLoaderTask {
        let task = Task(completion: completion)
        store.retrieve(dataForURL: url) { [weak self] result in
            guard self != nil else { return }

            switch result {
            case let .success(data?):
                task.complete(with: .success(data))

            case .success(.none):
                task.complete(with: .failure(Error.notFound))

            case .failure:
                task.complete(with: .failure(Error.failed))
            }
        }

        return task
    }

    public func save(_ imageData: Data, for url: URL, completion: @escaping (InsertionResult) -> Void) {
        store.insert(imageData, for: url, completion: completion)
    }
}
