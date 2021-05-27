//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public class LocalFeedLoader {
    public typealias SaveCompletion = (Result<Void, Error>) -> Void

    private let store: FeedStore
    private let currentDate: () -> Date

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(items: [FeedItem], completion: @escaping SaveCompletion) {
        store.deleteCachedFeed { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.cache(items: items, with: completion)

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func cache(items: [FeedItem], with completion: @escaping (Result<Void, Error>) -> Void) {
        store.insert(items: items, timestamp: self.currentDate()) { [weak self] result in
            guard self != nil else { return }

            completion(result)
        }
    }
}
