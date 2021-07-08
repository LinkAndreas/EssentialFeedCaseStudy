//  Copyright © 2021 Andreas Link. All rights reserved.

public protocol FeedLoader {
    typealias Result = Swift.Result<[FeedImage], Error>

    func fetchFeed(completion: @escaping (Result) -> Void)
}
