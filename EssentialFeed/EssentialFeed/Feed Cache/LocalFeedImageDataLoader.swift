//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public final class LocalFeedImageDataLoader {
    private let store: FeedImageDataStore

    public init(store: FeedImageDataStore) {
        self.store = store
    }
}

extension LocalFeedImageDataLoader: FeedImageDataLoader {
    public enum LoadError: Error {
        case failed
        case notFound
    }

    private final class LoadImageDataTask: FeedImageDataLoaderTask {
        private var completion: ((LoadResult) -> Void)?

        init(completion: @escaping (LoadResult) -> Void) {
            self.completion = completion
        }

        func complete(with result: LoadResult) {
            completion?(result)
        }

        func cancel() {
            preventFurtherCompletions()
        }

        private func preventFurtherCompletions() {
            completion = nil
        }
    }

    public func loadImageData(from url: URL, completion: @escaping (LoadResult) -> Void) -> FeedImageDataLoaderTask {
        let task = LoadImageDataTask(completion: completion)
        let result = Result<Data?, Error> {
            try store.retrieve(dataForURL: url)
        }

        switch result {
        case let .success(data?):
            task.complete(with: .success(data))

        case .success(.none):
            task.complete(with: .failure(LoadError.notFound))

        case .failure:
            task.complete(with: .failure(LoadError.failed))
        }

        return task
    }
}

extension LocalFeedImageDataLoader: FeedImageDataCache {
    public enum SaveError: Error {
        case failed
    }

    public func save(_ imageData: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {
        completion(SaveResult {
            try store.insert(imageData, for: url)
        }.mapError { _ in SaveError.failed })
    }
}
