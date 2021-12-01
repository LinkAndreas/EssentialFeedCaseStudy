//  Copyright © 2021 Andreas Link. All rights reserved.

public struct FeedErrorViewModel: Equatable {
    public let message: String?

    static let noError: Self = .init(message: nil)
    static func error(message: String?) -> Self {
        return .init(message: message)
    }
}
