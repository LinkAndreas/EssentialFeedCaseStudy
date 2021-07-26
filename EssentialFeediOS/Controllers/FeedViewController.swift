//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import UIKit

public final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
    private var refreshController: FeedRefreshViewController?
    private var imageLoader: FeedImageDataLoader?
     private var cellControllers: [IndexPath: FeedImageCellController] = [:]
    private var tableModel: [FeedImage] = [] {
        didSet { tableView.reloadData() }
    }

    public convenience init(loader: FeedLoader, imageLoader: FeedImageDataLoader) {
        self.init()

        self.refreshController = .init(feedLoader: loader)
        self.imageLoader = imageLoader
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = refreshController?.view
        refreshController?.onRefresh = { [weak self] feed in
            self?.tableModel = feed
        }

        tableView.prefetchDataSource = self
        refreshController?.refresh()
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellController = cellController(forRowAt: indexPath)
        return cellController.view()
    }

    public override func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        removeCellController(forRowAt: indexPath )
    }

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cellController(forRowAt: indexPath).preload()
         }
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(removeCellController)
    }

    private func cellController(forRowAt indexPath: IndexPath) -> FeedImageCellController {
        let model = tableModel[indexPath.row]
        let controller = FeedImageCellController(model: model, imageLoader: imageLoader!)
        cellControllers[indexPath] = controller
        return controller
    }

    private func removeCellController(forRowAt indexPath: IndexPath) {
        cellControllers[indexPath] = nil
    }
}
