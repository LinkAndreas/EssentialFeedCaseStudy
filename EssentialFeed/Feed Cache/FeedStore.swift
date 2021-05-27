//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = (Result<Void, Error>) -> Void
    typealias InsertionCompletion = (Result<Void, Error>) -> Void

    func insert(items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
}
