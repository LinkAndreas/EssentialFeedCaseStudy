//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import UIKit

public protocol FeedViewControllerDelegate: AnyObject {
    func didTriggerRefresh()
}

public final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching, FeedLoadingView, FeedErrorView {
    public var delegate: FeedViewControllerDelegate?
    private var tableModel: [FeedImageCellController] = [] {
        didSet { tableView.reloadData() }
    }

    @IBOutlet private(set) public var errorView: ErrorView?

    public override func viewDidLoad() {
        super.viewDidLoad()

        refresh()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.sizeTableHeaderToFit()
    }

    public func display(_ cellControllers: [FeedImageCellController]) {
        self.tableModel = cellControllers
    }

    public func display(_ viewModel: FeedLoadingViewModel) {
        refreshControl?.update(isRefreshing: viewModel.isLoading)
    }

    public func display(_ viewModel: FeedErrorViewModel) {
        if let errorMessage = viewModel.message {
            errorView?.show(message: errorMessage)
        } else {
            errorView?.hideMessage()
        }
    }

    @IBAction func refresh() {
        delegate?.didTriggerRefresh()
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellController(forRowAt: indexPath).view(in: tableView)
    }

    public override func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        cancelCellControllerLoad(forRowAt: indexPath)
    }

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(preload(forRowAt:))
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(cancelCellControllerLoad(forRowAt:))
    }

    private func preload(forRowAt indexPath: IndexPath) {
        cellController(forRowAt: indexPath).preload()
    }

    private func cancelCellControllerLoad(forRowAt indexPath: IndexPath) {
        cellController(forRowAt: indexPath).cancelLoad()
    }

    private func cellController(forRowAt indexPath: IndexPath) -> FeedImageCellController {
        return tableModel[indexPath.row]
    }
}
