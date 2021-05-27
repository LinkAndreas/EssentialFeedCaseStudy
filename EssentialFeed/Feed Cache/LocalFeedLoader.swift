//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public final class LocalFeedLoader {
    public typealias SaveResult = Result<Void, Error>

    private let store: FeedStore
    private let currentDate: () -> Date

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
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

    private func cache(items: [FeedItem], with completion: @escaping (SaveResult) -> Void) {
        store.insert(items: items, timestamp: self.currentDate()) { [weak self] result in
            guard self != nil else { return }

            completion(result)
        }
    }
}
