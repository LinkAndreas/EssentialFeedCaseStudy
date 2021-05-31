//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public enum RetrievalResult {
    case empty
    case found(feed: [LocalFeedImage], timestamp: Date)
    case failure(error: Error)
}

public protocol FeedStore {
    typealias DeletionCompletion = (Result<Void, Error>) -> Void
    typealias InsertionCompletion = (Result<Void, Error>) -> Void
    typealias RetrievalCompletion = (RetrievalResult) -> Void

    func insert(feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func load(completion: @escaping RetrievalCompletion)
}
