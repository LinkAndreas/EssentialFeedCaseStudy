//  Copyright © 2021 Andreas Link. All rights reserved.

public struct ResourceErrorViewModel: Equatable {
    public static let noError: Self = .init(message: nil)

    public static func error(message: String?) -> Self {
        return .init(message: message)
    }

    public let message: String?
}
