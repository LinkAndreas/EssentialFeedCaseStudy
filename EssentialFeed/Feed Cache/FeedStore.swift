//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public enum RetrieveCachedFeedResult {
    case empty
    case found(feed: [LocalFeedImage], timestamp: Date)
    case failure(error: Error)
}

public protocol FeedStore {
    typealias DeletionCompletion = (Result<Void, Error>) -> Void
    typealias InsertionCompletion = (Result<Void, Error>) -> Void
    typealias RetrievalCompletion = (RetrieveCachedFeedResult) -> Void

    // The comletion can be called in any Thread. Clients are responsible to dispatch in appropriate threads if needed.
    func insert(feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    // The comletion can be called in any Thread. Clients are responsible to dispatch in appropriate threads if needed.
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    // The comletion can be called in any Thread. Clients are responsible to dispatch in appropriate threads if needed.
    func retrieve(completion: @escaping RetrievalCompletion)
}
