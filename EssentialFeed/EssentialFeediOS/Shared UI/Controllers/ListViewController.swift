//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import UIKit

public final class ListViewController: UITableViewController, UITableViewDataSourcePrefetching, ResourceLoadingView, ResourceErrorView {
    public var onRefresh: (() -> Void)?

    private lazy var dataSource = UITableViewDiffableDataSource<Int, CellController>(
        tableView: tableView,
        cellProvider: { tableView, indexPath, controller in
            controller.dataSource.tableView(tableView, cellForRowAt: indexPath)
        }
    )

    private(set) public var errorView: ErrorView = ErrorView()

    public override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = dataSource
        setupErrorView()
        refresh()
    }

    private func setupErrorView() {
        errorView.onHide = { [weak self] in
            self?.tableView.beginUpdates()
            self?.tableView.sizeTableHeaderToFit()
            self?.tableView.endUpdates()
        }
        
        let container = UIView()
        container.backgroundColor = .clear
        container.addSubview(errorView)
        
        errorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            errorView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: errorView.trailingAnchor),
            errorView.topAnchor.constraint(equalTo: container.topAnchor),
            container.bottomAnchor.constraint(equalTo: errorView.bottomAnchor)
        ])
        
        tableView.tableHeaderView = container
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.sizeTableHeaderToFit()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard previousTraitCollection != traitCollection else { return }

        tableView.reloadData()
    }

    public func display(_ cellControllers: [CellController]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, CellController>()
        snapshot.appendSections([0])
        snapshot.appendItems(cellControllers)
        if #available(iOS 15.0, *) {
          dataSource.applySnapshotUsingReloadData(snapshot)
        } else {
          dataSource.apply(snapshot)
        }
    }

    public func display(_ viewModel: ResourceLoadingViewModel) {
        refreshControl?.update(isRefreshing: viewModel.isLoading)
    }

    public func display(_ viewModel: ResourceErrorViewModel) {
        errorView.message = viewModel.message
    }

    @IBAction func refresh() {
        onRefresh?()
    }

    public override func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        let controller = cellController(at: indexPath)
        controller?.dataSourcePrefetching?.tableView?(tableView, cancelPrefetchingForRowsAt: [indexPath])
    }

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(preload(forRowAt:))
    }

    public override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let controller = cellController(at: indexPath)
        controller?.delegate?.tableView?(tableView, willDisplay: cell, forRowAt: indexPath)
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let controller = cellController(at: indexPath)
            controller?.dataSourcePrefetching?.tableView?(tableView, cancelPrefetchingForRowsAt: [indexPath])
        }
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let controller = cellController(at: indexPath)
        controller?.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
    }

    private func preload(forRowAt indexPath: IndexPath) {
        let controller = cellController(at: indexPath)
        controller?.dataSourcePrefetching?.tableView(tableView, prefetchRowsAt: [indexPath])
    }

    private func cellController(at indexPath: IndexPath) -> CellController? {
        return dataSource.itemIdentifier(for: indexPath)
    }
}
