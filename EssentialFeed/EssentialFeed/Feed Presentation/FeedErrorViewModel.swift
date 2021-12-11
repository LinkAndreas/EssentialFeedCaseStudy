//  Copyright © 2021 Andreas Link. All rights reserved.

public struct FeedErrorViewModel: Equatable {
    public let message: String?

    public static let noError: Self = .init(message: nil)
    public static func error(message: String?) -> Self {
        return .init(message: message)
    }
}
