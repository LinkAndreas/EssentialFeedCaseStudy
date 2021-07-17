//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public enum CachedFeed {
    case empty
    case found(feed: [LocalFeedImage], timestamp: Date)
}
