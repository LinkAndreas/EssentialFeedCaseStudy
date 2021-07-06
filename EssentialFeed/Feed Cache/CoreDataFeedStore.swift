//  Copyright © 2021 Andreas Link. All rights reserved.

import CoreData

public final class CoreDataFeedStore: FeedStore {
    enum Constants {
        static let modelName = "FeedStore"
    }

    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    public init(storeURL: URL) throws {
        let bundle: Bundle = Bundle(for: CoreDataFeedStore.self)
        let model: NSManagedObjectModel = .with(name: Constants.modelName, in: bundle)!
        container = try .load(name: Constants.modelName, model: model, url: storeURL)
        context = container.newBackgroundContext()
    }

    public func insert(feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let context = self.context
        context.perform {
            do {
                let cache = ManagedCache(context: context)
                cache.timestamp = timestamp
                cache.feed = .init(array: feed.map { local in
                    let managed = ManagedFeedImage(context: context)
                    managed.cache = cache
                    managed.imageDescription = local.description
                    managed.location = local.location
                    managed.url = local.url
                    managed.id = local.id
                    return managed
                })

                try context.save()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {

    }

    public func retrieve(completion: @escaping RetrievalCompletion) {
        let context = self.context
        context.perform {
            do {
                if let cache = try ManagedCache.find(in: context) {
                    completion(
                        .found(
                            feed: cache.feed.array
                                .compactMap({ $0 as? ManagedFeedImage })
                                .map { managed in
                                    LocalFeedImage(
                                        id: managed.id,
                                        description: managed.imageDescription,
                                        location: managed.location,
                                        url: managed.url
                                    )
                                },
                            timestamp: cache.timestamp
                        )
                    )
                } else {
                    completion(.empty)
                }
            } catch {
                completion(.failure(error: error))
            }
        }
    }
}

@objc(ManagedCache)
private class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
}

extension ManagedCache {
    static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
        let request = NSFetchRequest<ManagedCache>(entityName: entity().name!)
        request.returnsObjectsAsFaults = false
        return try context.fetch(request).first
    }
}

@objc(ManagedFeedImage)
private class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
}
