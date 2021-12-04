//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import UIKit

struct WeakRef<T: AnyObject> {
    private weak var object: T?

    init(_ object: T?) {
        self.object = object
    }
}

extension WeakRef: FeedLoadingView where T: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        object?.display(viewModel)
    }
}

extension WeakRef: FeedErrorView where T: FeedErrorView {
    func display(_ viewModel: FeedErrorViewModel) {
        object?.display(viewModel)
    }
}

extension WeakRef: FeedImageView where T: FeedImageView, T.Image == UIImage {
    func display(_ model: FeedImageViewModel<UIImage>) {
        object?.display(model)
    }
}
