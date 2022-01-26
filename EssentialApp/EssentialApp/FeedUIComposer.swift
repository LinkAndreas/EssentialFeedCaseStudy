//  Copyright © 2021 Andreas Link. All rights reserved.

import Combine
import EssentialFeed
import EssentialFeediOS
import UIKit

public enum FeedUIComposer {
    public static func feedComposedWith(
        feedLoader: @escaping () -> AnyPublisher<[FeedImage], Error>,
        imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher
    ) -> ListViewController {
        let presentationAdapter = LoadResourcePresentationAdapter<[FeedImage], FeedViewAdapter>(
            loader: { feedLoader().dispatchOnMainQueue() }
        )

        let feedController = ListViewController.makeWith(delegate: presentationAdapter, title: FeedPresenter.title)
        presentationAdapter.presenter = LoadResourcePresenter(
            resourceView: FeedViewAdapter(
                controller: feedController,
                imageLoader: { url in imageLoader(url).dispatchOnMainQueue() }
            ),
            loadingView: WeakRef(feedController),
            errorView: WeakRef(feedController),
            mapper: FeedPresenter.map
        )
        return feedController
    }
}

private extension ListViewController {
    static func makeWith(delegate: FeedViewControllerDelegate, title: String) -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! ListViewController
        controller.delegate = delegate
        controller.title = title
        return controller
    }
}
