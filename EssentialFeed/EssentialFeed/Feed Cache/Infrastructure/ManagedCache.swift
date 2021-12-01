//  Copyright © 2021 Andreas Link. All rights reserved.

import CoreData

@objc(ManagedCache)
class ManagedCache: NSManagedObject {
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
