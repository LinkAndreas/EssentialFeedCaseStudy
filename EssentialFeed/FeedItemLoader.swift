//  Copyright © 2021 Andreas Link. All rights reserved.

protocol FeedItemLoader {
    func fetchItems(completion: @escaping (Result<[FeedItem], Error>) -> Void)
}
