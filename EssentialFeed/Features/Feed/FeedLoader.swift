//  Copyright © 2021 Andreas Link. All rights reserved.

protocol FeedLoader {
    func fetchItems(completion: (Result<[FeedItem], Error>) -> Void)
}
