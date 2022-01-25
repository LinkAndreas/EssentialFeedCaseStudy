//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public final class FeedImagePresenter {
    public static func map(_ model: FeedImage) -> FeedImageViewModel {
        FeedImageViewModel(
            description: model.description,
            location: model.location
        )
    }
}


