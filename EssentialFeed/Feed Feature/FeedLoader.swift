//  Copyright © 2021 Andreas Link. All rights reserved.

public protocol FeedLoader {
    typealias Result = Swift.Result<[FeedItem], Error>

    func fetchItems(completion: @escaping (Result) -> Void)
}