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
    static func data(with url: URL, in context: NSManagedObjectContext) throws -> Data? {
        if let data = context.userInfo[url] as? Data { return data }

        return try first(in: context, for: url)?.data
    }

    static func update(data: Data?, for url: URL, in context: NSManagedObjectContext) throws {
        let image = try first(in: context, for: url)
        image?.data = data
        context.userInfo[url] = data
        try context.save()
    }

    static func images(
        from localFeed: [LocalFeedImage],
        in context: NSManagedObjectContext
    ) -> NSOrderedSet {
        let images = NSOrderedSet(array: localFeed.map { local in
            let managed = ManagedFeedImage(context: context)
            managed.id = local.id
            managed.imageDescription = local.description
            managed.location = local.location
            managed.url = local.url
            managed.data = context.userInfo[local.url] as? Data
            return managed
        })
        context.userInfo.removeAllObjects()
        return images
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

    override func prepareForDeletion() {
        super.prepareForDeletion()

        managedObjectContext?.userInfo[url] = data
    }
}
