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

    public func insert(feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let context = self.context
        context.perform {
            completion(Result {
                let cache = try ManagedCache.newUniqueInstance(in: context)
                cache.timestamp = timestamp
                cache.feed = ManagedFeedImage.managed(from: feed, and: cache, in: context)
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

@objc(ManagedCache)
private class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
}

extension ManagedCache {
    static func find(in context: NSManagedObjectContext) throws -> [ManagedCache] {
        let request = NSFetchRequest<ManagedCache>(entityName: entity().name!)
        request.returnsObjectsAsFaults = false
        return try context.fetch(request)
    }

    static func newUniqueInstance(in context: NSManagedObjectContext) throws -> ManagedCache {
        try deleteAll(in: context)
        return ManagedCache(context: context)
    }

    static func deleteAll(in context: NSManagedObjectContext) throws {
        try find(in: context).forEach(context.delete)
    }

    var local: CachedFeed {
        return .init(feed: feed.compactMap({ ($0 as? ManagedFeedImage)?.local }), timestamp: timestamp)
    }
}

@objc(ManagedFeedImage)
private class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var data: Data?
    @NSManaged var cache: ManagedCache
}

extension ManagedFeedImage {
    static func managed(
        from localFeed: [LocalFeedImage],
        and cache: ManagedCache,
        in context: NSManagedObjectContext
    ) -> NSOrderedSet {
        let images = NSOrderedSet(array: localFeed.map { local in
            let managed = ManagedFeedImage(context: context)
            managed.id = local.id
            managed.imageDescription = local.description
            managed.location = local.location
            managed.url = local.url
            managed.cache = cache
            return managed
        })
        return images
    }

    var local: LocalFeedImage {
        return .init(id: id, description: imageDescription, location: location, url: url)
    }
}
