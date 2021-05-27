//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public final class RemoteFeedLoader: FeedLoader {
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    private let url: URL
    private let client: HTTPClient

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func fetchItems(completion: @escaping (FeedLoader.Result) -> Void) {
        client.load(from: url) { [weak self] response in
            guard self != nil else { return }

            switch response {
            case let .success((data, response)):
                completion(FeedItemsMapper.map(data: data, response: response))

            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
}
