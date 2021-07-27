//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import UIKit

public enum FeedUIComposer {
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let viewModel = FeedViewModel(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewController(viewModel: viewModel)
        let feedController = FeedViewController(refreshController: refreshController)
        viewModel.onFeedChanged = { [weak feedController] feed in
            feedController?.tableModel = feed.map { image in
                let viewModel = FeedImageViewModel(model: image, imageLoader: imageLoader, imageDataTransformer: UIImage.init)
                return FeedImageCellController(viewModel: viewModel)
            }
        }

        return feedController
    }
}
