//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public final class CodableFeedStore: FeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
    }

    private struct CodableFeedImage: Equatable, Codable {
        let id: UUID
        let description: String?
        let location: String?
        let url: URL

        init(id: UUID, description: String?, location: String?, url: URL) {
            self.id = id
            self.description = description
            self.location = location
            self.url = url
        }

        init(from feedImage: LocalFeedImage) {
            id = feedImage.id
            description = feedImage.description
            location = feedImage.location
            url = feedImage.url
        }

        var local: LocalFeedImage {
            return .init(id: id, description: description, location: location, url: url)
        }
    }

    private let storeURL: URL
    private let queue: DispatchQueue = .init(
        label: "\(CodableFeedStore.self)Queue",
        qos: .userInitiated,
        attributes: .concurrent
    )

    public init(storeURL: URL) {
        self.storeURL = storeURL
    }

    public func retrieve(completion: @escaping RetrievalCompletion) {
        let storeURL = self.storeURL
        queue.async {
            guard let data: Data = try? Data(contentsOf: storeURL) else {
                return completion(.empty)
            }

            let decoder: JSONDecoder = .init()
            do {
                let decoded = try decoder.decode(Cache.self, from: data)
                completion(.found(feed: decoded.feed.map(\.local), timestamp: decoded.timestamp))
            } catch {
                completion(.failure(error: error))
            }
        }
    }

    public func insert(feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let storeURL = self.storeURL
        queue.async(flags: .barrier) {
            let encoder: JSONEncoder = .init()
            do {
                let encoded = try encoder.encode(Cache(feed: feed.map(CodableFeedImage.init(from:)), timestamp: timestamp))
                try encoded.write(to: storeURL)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        let storeURL = self.storeURL
        queue.async(flags: .barrier) {
            guard FileManager.default.fileExists(atPath: storeURL.path) else { return completion(.success(())) }

            do {
                try FileManager.default.removeItem(at: storeURL)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
