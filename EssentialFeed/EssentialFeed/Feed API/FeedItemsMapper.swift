//  Copyright © 2021 Andreas Link. All rights reserved.

public enum FeedItemsMapper {
    private struct Root: Decodable {
        private var items: [Item]

        private struct Item: Decodable {
            let id: UUID
            let description: String?
            let location: String?
            let image: URL
        }

        var models: [FeedImage] {
            items.map {
                FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image)
            }
        }
    }

    public static func map(
        data: Data,
        response: HTTPURLResponse
    ) throws -> [FeedImage] {
        guard response.isOK, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData
        }

        return root.models
    }
}

