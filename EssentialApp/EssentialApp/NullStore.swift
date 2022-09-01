//  Copyright © 2022 Andreas Link. All rights reserved.

import EssentialFeed

final class NullStore: FeedStore & FeedImageDataStore {
    func insert(feed: [EssentialFeed.LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        completion(.success(()))
    }

    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        completion(.success(()))
    }

    func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.success(.none))
    }

    func retrieve(dataForURL url: URL) throws -> Data? {
        return nil
    }

    func insert(_ imageData: Data, for url: URL) throws {
        return
    }
}
