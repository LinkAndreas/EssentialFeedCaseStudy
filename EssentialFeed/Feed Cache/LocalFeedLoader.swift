//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public final class FeedCachePolicy {
    private var maxCacheAgeInDays: Int = 7

    private let calendar: Calendar = .init(identifier: .gregorian)

    func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard
            let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp)
        else { return false }

        return date < maxCacheAge
    }
}

public final class LocalFeedLoader: FeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    private let cachePolicy: FeedCachePolicy = .init()

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalFeedLoader {
    public typealias LoadResult = Result<[FeedImage], Error>

    public func fetchFeed(completion: @escaping (LoadResult) -> Void) {
        store.load { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .found(feed, timestamp) where self.cachePolicy.validate(timestamp, against: self.currentDate()):
                completion(.success(feed.toModels()))

            case .empty, .found:
                completion(.success([]))

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

extension LocalFeedLoader {
    public typealias SaveResult = Result<Void, Error>

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

    private func cache(feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(feed: feed.toLocal(), timestamp: self.currentDate()) { [weak self] result in
            guard self != nil else { return }

            completion(result)
        }
    }
}

extension LocalFeedLoader {
    public func validateCache() {
        store.load { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .found(_, timestamp) where !self.cachePolicy.validate(timestamp, against: self.currentDate()):
                self.store.deleteCachedFeed { _ in }

            case .failure:
                self.store.deleteCachedFeed { _ in }

            case .found, .empty:
                break
            }
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
