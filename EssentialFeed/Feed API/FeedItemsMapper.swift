//  Copyright © 2021 Andreas Link. All rights reserved.

internal enum FeedItemsMapper {
    private struct Root: Decodable {
        var items: [RemoteFeedItem]
    }

    private static let OK_200: UInt = 200

    internal static func map(
        data: Data,
        response: HTTPURLResponse
    ) throws -> [RemoteFeedItem] {
        guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData
        }

        return root.items
    }
}

