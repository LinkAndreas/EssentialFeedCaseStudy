//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import EssentialFeediOS
import UIKit

public final class FeedViewAdapter: ResourceView {
    private weak var controller: FeedViewController?
    private let imageLoader: (URL) -> FeedImageDataLoader.Publisher

    init(controller: FeedViewController, imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher) {
        self.controller = controller
        self.imageLoader = imageLoader
    }

    public func display(_ viewModel: FeedViewModel) {
        controller?.display(viewModel.feed.map { model in
            let adapter = LoadResourcePresentationAdapter<Data, WeakRef<FeedImageCellController>>(
                loader: { [imageLoader] in
                    imageLoader(model.url)
                }
            )
            let view = FeedImageCellController(
                viewModel: FeedImagePresenter.map(model),
                delegate: adapter
            )

            adapter.presenter = LoadResourcePresenter(
                resourceView: WeakRef(view),
                loadingView: WeakRef(view),
                errorView: WeakRef(view),
                mapper: mapper
            )
            return view
        })
    }

    private func mapper(data: Data) throws -> UIImage {
        guard let image = UIImage(data: data) else { throw InvalidImageData() }

        return image
    }
}

private struct InvalidImageData: Error {}
