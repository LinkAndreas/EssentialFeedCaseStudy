//  Copyright © 2021 Andreas Link. All rights reserved.

extension CoreDataFeedStore: FeedImageDataStore {
    public func insert(
        _ imageData: Data,
        for url: URL,
        completion: @escaping (FeedImageDataStore.InsertionResult) -> Void
    ) {
        perform { context in
            completion(Result {
                guard let image = try? ManagedFeedImage.first(in: context, for: url) else { return }

                image.data = imageData
                try? context.save()
            })
        }
    }

    public func retrieve(dataForURL url: URL, completion: @escaping (FeedImageDataStore.RetrievalResult) -> Void) {
        perform { context in
            completion(Result {
                return try ManagedFeedImage.first(in: context, for: url)?.data
            })
        }
    }
}
