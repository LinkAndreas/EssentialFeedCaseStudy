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
                do {
                    let remoteItems = try FeedItemsMapper.map(data: data, response: response)
                    completion(.success(remoteItems.toModels()))
                } catch {
                    completion(.failure(error))
                }


            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
}

private extension Array where Element == RemoteFeedItem {
    func toModels() -> [FeedItem] {
        self.map { item in
            .init(
                id: item.id,
                description: item.description,
                location: item.location,
                imageURL: item.image
            )
        }
    }
}
