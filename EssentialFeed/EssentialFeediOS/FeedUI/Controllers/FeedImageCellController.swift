//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import UIKit

public protocol FeedImageCellControllerDelegate: AnyObject {
    func didTriggerPreload()
    func didRequestImage()
    func didCancelLoad()
}

public final class FeedImageCellController: NSObject {
    public typealias ResourceViewModel = UIImage

    private let viewModel: FeedImageViewModel
    public let delegate: FeedImageCellControllerDelegate
    private let selection: () -> Void
    private var cell: FeedImageCell?

    public init(
        viewModel: FeedImageViewModel,
        delegate: FeedImageCellControllerDelegate,
        selection: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.selection = selection
    }
}

extension FeedImageCellController: UITableViewDataSource, UITableViewDelegate, UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cell = tableView.dequeueReusableCell()
        cell?.locationContainer?.isHidden = !viewModel.hasLocation
        cell?.locationLabel?.text = viewModel.location
        cell?.descriptionLabel?.text = viewModel.description
        cell?.feedImageView.image = nil
        cell?.onRetry = { [weak self] in self?.delegate.didRequestImage() }
        delegate.didRequestImage()
        return cell!
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selection()
    }

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        delegate.didTriggerPreload()
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        cancelLoad()
    }

    private func cancelLoad() {
        releaseCellForReuse()
        delegate.didCancelLoad()
    }

    private func releaseCellForReuse() {
        cell = nil
    }
}

extension FeedImageCellController: ResourceView, ResourceLoadingView, ResourceErrorView {
    public func display(_ viewModel: ResourceLoadingViewModel) {
        cell?.feedImageContainer?.isShimmering = viewModel.isLoading
    }

    public func display(_ viewModel: ResourceErrorViewModel) {
        cell?.feedImageRetryButton?.isHidden = viewModel.message == nil
    }

    public func display(_ viewModel: UIImage) {
        cell?.feedImageView?.setAnimated(viewModel)
    }
}
