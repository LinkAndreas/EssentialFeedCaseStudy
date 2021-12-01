//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public struct CachedFeed: Equatable {
    public let feed: [LocalFeedImage]
    public let timestamp: Date

    public init(feed: [LocalFeedImage], timestamp: Date) {
        self.feed = feed
        self.timestamp = timestamp
    }
}
