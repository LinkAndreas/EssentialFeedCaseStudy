//  Copyright © 2021 Andreas Link. All rights reserved.

public struct ResourceLoadingViewModel: Equatable {
    public let isLoading: Bool

    public init(isLoading: Bool) {
        self.isLoading = isLoading
    }
}
