//  Copyright © 2021 Andreas Link. All rights reserved.

extension CoreDataFeedStore: FeedImageDataStore {
    public func insert(
        _ imageData: Data,
        for url: URL,
        completion: @escaping (FeedImageDataStore.InsertionResult) -> Void
    ) {
        perform { context in
            completion(Result {
                try ManagedFeedImage.update(data: imageData, for: url, in: context)
            })
        }
    }

    public func retrieve(dataForURL url: URL, completion: @escaping (FeedImageDataStore.RetrievalResult) -> Void) {
        perform { context in
            completion(Result {
                try ManagedFeedImage.data(with: url, in: context)
            })
        }
    }
}
