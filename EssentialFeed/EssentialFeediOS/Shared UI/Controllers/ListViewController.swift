//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import UIKit

public typealias CellController = UITableViewDelegate & UITableViewDataSource & UITableViewDataSourcePrefetching

public final class ListViewController: UITableViewController, UITableViewDataSourcePrefetching, ResourceLoadingView, ResourceErrorView {
    public var onRefresh: (() -> Void)?
    private var loadingControllers: [IndexPath: CellController] = [:]
    private var tableModel: [CellController] = [] {
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

    public func display(_ cellControllers: [CellController]) {
        self.loadingControllers = [:]
        self.tableModel = cellControllers
    }

    public func display(_ viewModel: ResourceLoadingViewModel) {
        refreshControl?.update(isRefreshing: viewModel.isLoading)
    }

    public func display(_ viewModel: ResourceErrorViewModel) {
        if let errorMessage = viewModel.message {
            errorView?.show(message: errorMessage)
        } else {
            errorView?.hideMessage()
        }
    }

    @IBAction func refresh() {
        onRefresh?()
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellController(forRowAt: indexPath).tableView(tableView, cellForRowAt: indexPath)
    }

    public override func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        let controller = removeLoadingController(forRowAt: indexPath)
        controller?.tableView?(tableView, cancelPrefetchingForRowsAt: [indexPath])
    }

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(preload(forRowAt:))
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let controller = loadingControllers[indexPath]
            controller?.tableView?(tableView, cancelPrefetchingForRowsAt: [indexPath])
        }
    }

    private func preload(forRowAt indexPath: IndexPath) {
        cellController(forRowAt: indexPath).tableView(tableView, prefetchRowsAt: [indexPath])
    }

    private func removeLoadingController(forRowAt indexPath: IndexPath) -> CellController? {
        let controller = loadingControllers[indexPath]
        loadingControllers[indexPath] = nil
        return controller
    }

    private func cellController(forRowAt indexPath: IndexPath) -> CellController {
        let controller = tableModel[indexPath.row]
        loadingControllers[indexPath] = controller
        return controller
    }
}
