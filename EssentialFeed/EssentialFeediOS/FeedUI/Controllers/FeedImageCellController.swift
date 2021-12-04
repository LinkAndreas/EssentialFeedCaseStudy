//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import UIKit

public protocol FeedImageCellControllerDelegate: AnyObject {
    func didTriggerPreload()
    func didRequestImage()
    func didCancelLoad()
}

public final class FeedImageCellController: FeedImageView {
    public let delegate: FeedImageCellControllerDelegate

    private var cell: FeedImageCell?

    public init(delegate: FeedImageCellControllerDelegate) {
        self.delegate = delegate
    }

    func view(in tableView: UITableView) -> UITableViewCell {
        cell = tableView.dequeueReusableCell()
        delegate.didRequestImage()
        return cell!
    }

    func preload() {
        delegate.didTriggerPreload()
    }

    func cancelLoad() {
        releaseCellForReuse()
        delegate.didCancelLoad()
    }

    public func display(_ viewModel: FeedImageViewModel<UIImage>) {
        cell?.locationContainer?.isHidden = !viewModel.hasLocation
        cell?.locationLabel?.text = viewModel.location
        cell?.descriptionLabel?.text = viewModel.description
        cell?.feedImageView?.setAnimated(viewModel.image)
        cell?.feedImageRetryButton?.isHidden = !viewModel.shouldRetry
        cell?.feedImageContainer?.isShimmering = viewModel.isLoading
        cell?.onRetry = delegate.didRequestImage
    }

    private func releaseCellForReuse() {
        cell = nil
    }
}
