//  Copyright © 2021 Andreas Link. All rights reserved.

import CoreData

@objc(ManagedFeedImage)
class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var data: Data?
    @NSManaged var cache: ManagedCache
}

extension ManagedFeedImage {
    static func images(
        from localFeed: [LocalFeedImage],
        in context: NSManagedObjectContext
    ) -> NSOrderedSet {
        return NSOrderedSet(array: localFeed.map { local in
            let managed = ManagedFeedImage(context: context)
            managed.id = local.id
            managed.imageDescription = local.description
            managed.location = local.location
            managed.url = local.url
            return managed
        })
    }

    static func first(in context: NSManagedObjectContext, for url: URL) throws -> ManagedFeedImage? {
        let request = NSFetchRequest<ManagedFeedImage>.init(entityName: entity().name!)
        request.predicate = NSPredicate(format: "%K = %@", argumentArray: [#keyPath(ManagedFeedImage.url), url])
        request.fetchLimit = 1
        request.returnsObjectsAsFaults = false
        return try context.fetch(request).first
    }

    var local: LocalFeedImage {
        return .init(id: id, description: imageDescription, location: location, url: url)
    }
}
