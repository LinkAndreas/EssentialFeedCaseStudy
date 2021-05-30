//  Copyright © 2021 Andreas Link. All rights reserved.

public struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
