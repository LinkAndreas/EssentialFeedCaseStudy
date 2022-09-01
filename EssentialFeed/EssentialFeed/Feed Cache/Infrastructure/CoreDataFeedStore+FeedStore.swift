//  Copyright © 2021 Andreas Link. All rights reserved.

import CoreData

extension CoreDataFeedStore: FeedStore {
    public func insert(feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        performAsync { context in
            completion(Result {
                let cache = try ManagedCache.newUniqueInstance(in: context)
                cache.timestamp = timestamp
                cache.feed = ManagedFeedImage.images(from: feed, in: context)
                try context.save()
            })
        }
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        performAsync { context in
            completion(Result {
                try ManagedCache.deleteAll(in: context)
            })
        }
    }

    public func retrieve(completion: @escaping RetrievalCompletion) {
        performAsync { context in
            completion(Result {
                try ManagedCache.find(in: context).first?.local
            })
        }
    }
}
