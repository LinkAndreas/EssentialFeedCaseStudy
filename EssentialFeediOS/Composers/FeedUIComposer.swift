//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import UIKit

public enum FeedUIComposer {
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let presentationAdapter = FeedLoaderPresentationAdapter(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewController(delegate: presentationAdapter)
        let feedController = FeedViewController(refreshController: refreshController)
        presentationAdapter.presenter = FeedPresenter(
            loadingView: WeakRef(refreshController),
            feedView: FeedViewAdapter(controller: feedController, imageLoader: imageLoader)
        )
        return feedController
    }
}

public final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private let imageLoader: FeedImageDataLoader

    init(controller: FeedViewController, imageLoader: FeedImageDataLoader) {
        self.controller = controller
        self.imageLoader = imageLoader
    }

    func display(_ viewModel: FeedViewModel) {
        controller?.tableModel = viewModel.feed.map { image in
            let viewModel = FeedImageViewModel(
                model: image,
                imageLoader: imageLoader,
                imageDataTransformer: UIImage.init
            )
            return FeedImageCellController(viewModel: viewModel)
        }
    }
}

final class FeedLoaderPresentationAdapter: FeedRefreshViewControllerDelegate {
    var presenter: FeedPresenter?

    private let feedLoader: FeedLoader

    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    func didTriggerRefresh() {
        presenter?.didStartLoadingFeed()
        feedLoader.fetchFeed { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .success(feed):
                self.presenter?.didFinishLoading(feed: feed)

            case let .failure(error):
                self.presenter?.didFinishLoading(with: error)
            }
        }
    }
}

struct WeakRef<T: AnyObject> {
    private weak var object: T?

    init(_ object: T) {
        self.object = object
    }
}

extension WeakRef: FeedLoadingView where T: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        object?.display(viewModel)
    }
}
