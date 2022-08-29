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

    public func loadImageData(from url: URL) throws -> Data {
        let result = Result<Data?, Error> {
            try store.retrieve(dataForURL: url)
        }

        switch result {
        case let .success(data?):
            return data

        case .success(.none):
            throw LoadError.notFound

        case .failure:
            throw LoadError.failed
        }
    }
}

extension LocalFeedImageDataLoader: FeedImageDataCache {
    public enum SaveError: Error {
        case failed
    }

    public func save(_ imageData: Data, for url: URL) throws {
        do {
            try store.insert(imageData, for: url)
        } catch {
            throw SaveError.failed
        }
    }
}
