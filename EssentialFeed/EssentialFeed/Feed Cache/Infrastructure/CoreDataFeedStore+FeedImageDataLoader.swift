//  Copyright © 2021 Andreas Link. All rights reserved.

extension CoreDataFeedStore: FeedImageDataStore {
    public func insert(_ imageData: Data, for url: URL) throws {
        try performSync { context in
            Result {
                try ManagedFeedImage.update(data: imageData, for: url, in: context)
            }
        }
    }

    public func retrieve(dataForURL url: URL) throws -> Data? {
        try performSync { context in
            Result {
                try ManagedFeedImage.data(with: url, in: context)
            }
        }
    }
}
