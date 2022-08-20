//  Copyright © 2021 Andreas Link. All rights reserved.

import Combine
import EssentialFeed
import EssentialFeediOS
import UIKit

public enum FeedUIComposer {
    public static func feedComposedWith(
        feedLoader: @escaping () -> AnyPublisher<Paginated<FeedImage>, Error>,
        imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher,
        selection: @escaping (FeedImage) -> Void
    ) -> ListViewController {
        let presentationAdapter = LoadResourcePresentationAdapter<Paginated<FeedImage>, FeedViewAdapter>(
            loader: { feedLoader().dispatchOnMainQueue() }
        )

        let controller = ListViewController.makeWith(title: FeedPresenter.title)
        controller.onRefresh = presentationAdapter.loadResource
        presentationAdapter.presenter = LoadResourcePresenter(
            resourceView: FeedViewAdapter(
                controller: controller,
                imageLoader: { url in imageLoader(url).dispatchOnMainQueue() },
                selection: selection
            ),
            loadingView: WeakRef(controller),
            errorView: WeakRef(controller),
            mapper: { $0 }
        )
        return controller
    }
}

private extension ListViewController {
    static func makeWith(title: String) -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! ListViewController
        controller.title = title
        return controller
    }
}
