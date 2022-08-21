//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import EssentialFeediOS
import UIKit

public final class FeedViewAdapter: ResourceView {
    typealias ImageDataPresentationAdapter = LoadResourcePresentationAdapter<Data, WeakRef<FeedImageCellController>>
    typealias LoadMorePresentationAdapter = LoadResourcePresentationAdapter<Paginated<FeedImage>, FeedViewAdapter>

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
        let feedSection: [CellController] = viewModel.items.map { model in
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
        }

        guard let loadMorePublisher = viewModel.loadMorePublisher else {
            controller?.display(feedSection)
            return
        }

        let loadMoreAdapter = LoadMorePresentationAdapter(
            loader: { loadMorePublisher.dispatchOnMainQueue() }
        )
        let loadMore = LoadMoreCellController(callback: loadMoreAdapter.loadResource)
        loadMoreAdapter.presenter = LoadResourcePresenter(
            resourceView: self,
            loadingView: WeakRef(loadMore),
            errorView: WeakRef(loadMore),
            mapper: { $0 }
        )
        
        let loadMoreSection: [CellController] = [CellController(id: UUID(), dataSource: loadMore, delegate: loadMore)]

        controller?.display(feedSection, loadMoreSection)
    }

    private func mapper(data: Data) throws -> UIImage {
        guard let image = UIImage(data: data) else { throw InvalidImageData() }

        return image
    }
}

private struct InvalidImageData: Error {}
