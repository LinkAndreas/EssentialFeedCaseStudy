//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol HttpClient {
    func load(from url: URL, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void)
}

public class RemoteFeedLoader {
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
                do {
                    let items: [FeedItem] = try FeedItemMapper.map(data: data, response: response)
                    completion(.success(items))
                } catch {
                    completion(.failure(.invalidData))
                }

            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

enum FeedItemMapper {
    private struct Root: Decodable {
        var items: [Item]
    }

    private struct Item: Decodable {
        let id: String
        let description: String?
        let location: String?
        let imageUrl: String

        var item: FeedItem {
            return .init(
                id: UUID(uuidString: id)!,
                description: description,
                location: location,
                imageURL: URL.init(string: imageUrl)!
            )
        }
    }

    static func map(data: Data, response: HTTPURLResponse) throws -> [FeedItem] {
        guard
            let root = try? JSONDecoder().decode(Root.self, from: data),
            response.statusCode == 200
        else {
            throw RemoteFeedLoader.Error.invalidData
        }

        return root.items.map(\.item)
    }
}

