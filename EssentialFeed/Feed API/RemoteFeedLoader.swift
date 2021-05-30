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
                completion(RemoteFeedLoader.map(data: data, response: response))

            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }

    static func map(data: Data, response: HTTPURLResponse) -> FeedLoader.Result {
        do {
            let remoteItems = try FeedItemsMapper.map(data: data, response: response)
            return .success(remoteItems.toModels())
        } catch {
            return .failure(error)
        }
    }
}

private extension Array where Element == RemoteFeedItem {
    func toModels() -> [FeedImage] {
        self.map { item in
            .init(
                id: item.id,
                description: item.description,
                location: item.location,
                url: item.image
            )
        }
    }
}
