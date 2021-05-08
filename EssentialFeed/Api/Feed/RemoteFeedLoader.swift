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
        client.load(from: url) { [weak self] response in
            guard let self = self else { return }

            switch response {
            case let .success((data, response)):
                completion(self.map(data: data, response: response))

            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }

    private func map(data: Data, response: HTTPURLResponse) -> Result<[FeedItem], Error> {
        do {
            let items: [FeedItem] = try FeedItemsMapper.map(data: data, response: response)
            return .success(items)
        } catch {
            return .failure(.invalidData)
        }
    }
}
