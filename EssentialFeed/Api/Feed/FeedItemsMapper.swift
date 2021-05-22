//  Copyright © 2021 Andreas Link. All rights reserved.

internal enum FeedItemsMapper {
    private struct Root: Decodable {
        var items: [Item]
    }

    fileprivate struct Item: Decodable {
        let id: String
        let description: String?
        let location: String?
        let image: String
    }

    private static let OK_200: UInt = 200

    internal static func map(
        data: Data,
        response: HTTPURLResponse
    ) -> FeedLoader.Result {
        guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }

        return .success(root.items.map(FeedItem.init(from:)))
    }
}

extension FeedItem {
    fileprivate init(from item: FeedItemsMapper.Item) {
        self = .init(
            id: UUID(uuidString: item.id)!,
            description: item.description,
            location: item.location,
            imageURL: URL.init(string: item.image)!
        )
    }
}

