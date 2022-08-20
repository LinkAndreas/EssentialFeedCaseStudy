//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import EssentialFeediOS
import UIKit

public final class FeedViewAdapter: ResourceView {
    private weak var controller: ListViewController?
    private let imageLoader: (URL) -> FeedImageDataLoader.Publisher
    private let selection: (FeedImage) -> Void

    init(
        controller: ListViewController,
        imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher,
        selection: @escaping (FeedImage) -> Void
    ) {
        self.controller = controller
        self.imageLoader = imageLoader
        self.selection = selection
    }

    public func display(_ viewModel: Paginated<FeedImage>) {
        controller?.display(viewModel.items.map { model in
            let adapter = LoadResourcePresentationAdapter<Data, WeakRef<FeedImageCellController>>(
                loader: { [imageLoader] in
                    imageLoader(model.url)
                }
            )
            let view = FeedImageCellController(
                viewModel: FeedImagePresenter.map(model),
                delegate: adapter,
                selection: { [selection] in
                    selection(model)
                }
            )

            adapter.presenter = LoadResourcePresenter(
                resourceView: WeakRef(view),
                loadingView: WeakRef(view),
                errorView: WeakRef(view),
                mapper: mapper
            )

            return CellController(
                id: model,
                dataSource: view,
                delegate: view,
                dataSourcePrefetching: view
            )
        })
    }

    private func mapper(data: Data) throws -> UIImage {
        guard let image = UIImage(data: data) else { throw InvalidImageData() }

        return image
    }
}

private struct InvalidImageData: Error {}
