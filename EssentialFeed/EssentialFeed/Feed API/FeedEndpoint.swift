//  Copyright © 2022 Andreas Link. All rights reserved.

import Foundation

public enum FeedEndpoint {
    case get
}

extension FeedEndpoint {
    public func url(baseURL: URL) -> URL {
        switch self {
        case .get:
            return baseURL.appendingPathComponent("v1/feed")
        }
    }
}
