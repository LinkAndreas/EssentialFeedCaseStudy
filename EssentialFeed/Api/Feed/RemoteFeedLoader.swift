//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol HttpClient {
    func load(from url: URL, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void)
}

public final class RemoteFeedLoader {
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    private let url: URL
    private let client: HttpClient

    public init(url: URL, client: HttpClient) {
        self.url = url
        self.client = client
    }

    public func fetchItems(completion: @escaping (Result<[FeedItem], Error>) -> Void) {
        client.load(from: url) { response in
            switch response {
            case let .success((data, response)):
                completion(FeedItemsMapper.map(data: data, response: response))

            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
