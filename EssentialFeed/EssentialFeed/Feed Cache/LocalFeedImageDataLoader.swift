//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public final class LocalFeedImageDataLoader {
    private let store: FeedImageDataStore

    public init(store: FeedImageDataStore) {
        self.store = store
    }
}

extension LocalFeedImageDataLoader {
    public enum LoadError: Error {
        case failed
        case notFound
    }

    public typealias LoadResult = Swift.Result<Data?, Error>

    private final class LoadImageDataTask: FeedImageDataLoaderTask {
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

    public func loadImageData(from url: URL, completion: @escaping (LoadResult) -> Void) -> FeedImageDataLoaderTask {
        let task = LoadImageDataTask(completion: completion)
        store.retrieve(dataForURL: url) { [weak self] result in
            guard self != nil else { return }

            switch result {
            case let .success(data?):
                task.complete(with: .success(data))

            case .success(.none):
                task.complete(with: .failure(LoadError.notFound))

            case .failure:
                task.complete(with: .failure(LoadError.failed))
            }
        }

        return task
    }
}

extension LocalFeedImageDataLoader {
    public enum SaveError: Error {
        case failed
    }

    public typealias SaveResult = Swift.Result<Void, Swift.Error>

    public func save(_ imageData: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {
        store.insert(imageData, for: url) { [weak self] result in
            guard self != nil else { return }

            completion(result.mapError { _ in SaveError.failed })
        }
    }
}
