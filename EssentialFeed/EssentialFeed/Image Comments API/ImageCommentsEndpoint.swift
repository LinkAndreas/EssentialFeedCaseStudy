//  Copyright © 2022 Andreas Link. All rights reserved.

import Foundation

public enum ImageCommentsEndpoint {
    case get(UUID)
}

extension ImageCommentsEndpoint {
    public func url(baseURL: URL) -> URL {
        switch self {
        case let .get(id):
            return baseURL.appendingPathComponent("v1/image/\(id)/comments")
        }
    }
}
