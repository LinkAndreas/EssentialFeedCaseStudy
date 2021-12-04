//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import EssentialFeediOS
import UIKit

public final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private let imageLoader: FeedImageDataLoader

    init(controller: FeedViewController, imageLoader: FeedImageDataLoader) {
        self.controller = controller
        self.imageLoader = imageLoader
    }

    public func display(_ viewModel: FeedViewModel) {
        controller?.display(viewModel.feed.map { image in
            let adapter = FeedImageDataLoaderPresentationAdapter<WeakRef<FeedImageCellController>, UIImage>(
                model: image,
                imageLoader: imageLoader
            )
            let view = FeedImageCellController(delegate: adapter)
            adapter.presenter = FeedImagePresenter(view: WeakRef(view), imageDataTransformer: UIImage.init)
            return view
        })
    }
}
