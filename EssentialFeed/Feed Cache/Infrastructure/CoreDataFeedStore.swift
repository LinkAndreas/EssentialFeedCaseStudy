//  Copyright © 2021 Andreas Link. All rights reserved.

import CoreData

public final class CoreDataFeedStore {
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

    deinit {
        cleanUpReferencesToPersistentStores()
    }

    func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
        let context = self.context
        context.perform { action(context) }
    }

    func cleanUpReferencesToPersistentStores() {
        context.performAndWait {
            let coordinator = self.container.persistentStoreCoordinator
            try? coordinator.persistentStores.forEach(coordinator.remove)
        }
    }
}
