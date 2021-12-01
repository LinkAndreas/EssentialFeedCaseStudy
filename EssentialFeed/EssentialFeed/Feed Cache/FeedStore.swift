//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol FeedStore {
    typealias DeletionResult = Swift.Result<Void, Error>
    typealias DeletionCompletion = (DeletionResult) -> Void

    typealias InsertionResult = Swift.Result<Void, Error>
    typealias InsertionCompletion = (InsertionResult) -> Void

    typealias RetrievalResult = Swift.Result<CachedFeed?, Error>
    typealias RetrievalCompletion = (RetrievalResult) -> Void

    // The comletion can be called in any Thread. Clients are responsible to dispatch in appropriate threads if needed.
    func insert(feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    // The comletion can be called in any Thread. Clients are responsible to dispatch in appropriate threads if needed.
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    // The comletion can be called in any Thread. Clients are responsible to dispatch in appropriate threads if needed.
    func retrieve(completion: @escaping RetrievalCompletion)
}
