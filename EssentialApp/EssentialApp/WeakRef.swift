//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import UIKit

struct WeakRef<T: AnyObject> {
    private weak var object: T?

    init(_ object: T?) {
        self.object = object
    }
}

extension WeakRef: ResourceLoadingView where T: ResourceLoadingView {
    func display(_ viewModel: ResourceLoadingViewModel) {
        object?.display(viewModel)
    }
}

extension WeakRef: ResourceErrorView where T: ResourceErrorView {
    func display(_ viewModel: ResourceErrorViewModel) {
        object?.display(viewModel)
    }
}

extension WeakRef: FeedImageView where T: FeedImageView, T.Image == UIImage {
    func display(_ model: FeedImageViewModel<UIImage>) {
        object?.display(model)
    }
}
