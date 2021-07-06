//  Copyright © 2021 Andreas Link. All rights reserved.

import CoreData

public final class CoreDataFeedStore: FeedStore {
    private let container: NSPersistentContainer

    public init(bundle: Bundle = .main) throws {
        self.container = try .load(modelName: "FeedStore", in: bundle)
    }

    public func insert(feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {

    }

    public func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.empty)
    }
}

private class ManagedCache: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedCache> {
        return NSFetchRequest<ManagedCache>(entityName: "ManagedCache")
    }

    @NSManaged var timestamp: Date?
    @NSManaged var feed: NSOrderedSet?
}

private class ManagagedFeedImage: NSManagedObject, Identifiable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagagedFeedImage> {
        return NSFetchRequest<ManagagedFeedImage>(entityName: "ManagagedFeedImage")
    }

    @NSManaged var id: UUID?
    @NSManaged var imageDescription: String?
    @NSManaged var url: URL?
    @NSManaged var location: String?
    @NSManaged var cache: ManagedCache?
}
