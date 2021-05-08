//  Copyright © 2021 Andreas Link. All rights reserved.

enum FeedItemsMapper {
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
