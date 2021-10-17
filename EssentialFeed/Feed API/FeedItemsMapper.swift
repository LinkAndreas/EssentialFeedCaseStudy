//  Copyright © 2021 Andreas Link. All rights reserved.

internal enum FeedItemsMapper {
    private struct Root: Decodable {
        var items: [RemoteFeedItem]
    }

    internal static func map(
        data: Data,
        response: HTTPURLResponse
    ) throws -> [RemoteFeedItem] {
        guard response.isOK, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData
        }

        return root.items
    }
}

