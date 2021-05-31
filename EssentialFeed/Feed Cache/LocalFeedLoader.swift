//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public final class LocalFeedLoader {
    public typealias SaveResult = Result<Void, Error>
    public typealias LoadResult = Result<[FeedImage], Error>

    private let store: FeedStore
    private let currentDate: () -> Date

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.cache(feed: feed, with: completion)

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func loadFeed(completion: @escaping (LoadResult) -> Void) {
        store.load { [unowned self] result in
            switch result {
            case let .found(feed, timestamp) where self.validate(timestamp):
                completion(.success(feed.toModels()))

            case .empty, .found:
                completion(.success([]))

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func validate(_ timestamp: Date) -> Bool {
        let calendar: Calendar = .init(identifier: .gregorian)
        guard let maxCacheAge = calendar.date(byAdding: .day, value: 7, to: timestamp) else { return false }

        return currentDate() < maxCacheAge
    }

    private func cache(feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(feed: feed.toLocal(), timestamp: self.currentDate()) { [weak self] result in
            guard self != nil else { return }

            completion(result)
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map {
            LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
        }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return map {
            FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
        }
    }
}
