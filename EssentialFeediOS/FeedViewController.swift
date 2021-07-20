//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import UIKit

public protocol FeedImageDataLoaderTask {
    func cancel()
}

public protocol FeedImageDataLoader {
    func loadImageData(from url: URL) -> FeedImageDataLoaderTask
}

public final class FeedViewController: UITableViewController {
    private var feedLoader: FeedLoader?
    private var imageLoader: FeedImageDataLoader?
    private var tableModel: [FeedImage] = []
    private var tasks: [IndexPath: FeedImageDataLoaderTask] = [:]

    public convenience init(loader: FeedLoader, imageLoader: FeedImageDataLoader) {
        self.init()

        self.feedLoader = loader
        self.imageLoader = imageLoader
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        load()
    }

    @objc
    private func load() {
        refreshControl?.beginRefreshing()
        feedLoader?.fetchFeed { [weak self] result in
            guard let self = self else { return }

            if let feed = try? result.get() {
                self.tableModel = feed
                self.tableView.reloadData()
            }

            self.refreshControl?.endRefreshing()
        }
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = tableModel[indexPath.row]
        let cell = FeedImageCell()
        cell.descriptionLabel.text = cellModel.description
        cell.locationContainer.isHidden = cellModel.location == nil
        cell.locationLabel.text = cellModel.location
        tasks[indexPath] = imageLoader?.loadImageData(from: cellModel.url)
        return cell
    }

    public override func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        tasks[indexPath]?.cancel()
        tasks[indexPath] = nil
    }
}
