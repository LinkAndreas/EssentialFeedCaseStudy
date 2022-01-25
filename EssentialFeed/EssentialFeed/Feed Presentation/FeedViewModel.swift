//  Copyright © 2021 Andreas Link. All rights reserved.

public struct FeedViewModel: Hashable {
    public let feed: [FeedImage]

    public init(feed: [FeedImage]) {
        self.feed = feed
    }
}
