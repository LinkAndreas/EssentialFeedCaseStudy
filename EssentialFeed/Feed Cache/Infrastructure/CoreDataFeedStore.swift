//  Copyright © 2021 Andreas Link. All rights reserved.

import CoreData

public final class CoreDataFeedStore: FeedStore {
    enum Constants {
        static let modelName = "FeedStore"
    }

    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    public init(storeURL: URL, bundle: Bundle) throws {
        let model: NSManagedObjectModel = .with(name: Constants.modelName, in: bundle)!
        container = try .load(name: Constants.modelName, model: model, url: storeURL)
        context = container.newBackgroundContext()
    }

    func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
        let context = self.context
        context.perform { action(context) }
    }

    public func insert(feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let context = self.context
        context.perform {
            completion(Result {
                let cache = try ManagedCache.newUniqueInstance(in: context)
                cache.timestamp = timestamp
                cache.feed = ManagedFeedImage.images(from: feed, in: context)
                try context.save()
            })
        }
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        let context = self.context
        context.perform {
            completion(Result {
                try ManagedCache.deleteAll(in: context)
            })
        }
    }

    public func retrieve(completion: @escaping RetrievalCompletion) {
        let context = self.context
        context.perform {
            completion(Result {
                try ManagedCache.find(in: context).first?.local
            })
        }
    }
}
