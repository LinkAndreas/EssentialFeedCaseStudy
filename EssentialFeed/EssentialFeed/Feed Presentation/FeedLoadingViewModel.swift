//  Copyright © 2021 Andreas Link. All rights reserved.

public struct FeedLoadingViewModel: Equatable {
    public let isLoading: Bool

    public init(isLoading: Bool) {
        self.isLoading = isLoading
    }
}
