//  Copyright © 2021 Andreas Link. All rights reserved.

import UIKit

protocol FeedImageCellControllerDelegate: AnyObject {
    func didTriggerPreload()
    func didRequestImage()
    func didCancelLoad()
}

final class FeedImageCellController: FeedImageView {
    let delegate: FeedImageCellControllerDelegate

    private var cell: FeedImageCell?

    init(delegate: FeedImageCellControllerDelegate) {
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

    func display(_ viewModel: FeedImageViewModel<UIImage>) {
        cell?.locationContainer?.isHidden = !viewModel.hasLocation
        cell?.locationLabel?.text = viewModel.location
        cell?.descriptionLabel?.text = viewModel.description
        cell?.feedImageView?.image = viewModel.image
        cell?.feedImageRetryButton?.isHidden = !viewModel.shouldRetry
        cell?.feedImageContainer?.isShimmering = viewModel.isLoading
        cell?.onRetry = delegate.didRequestImage
    }

    private func releaseCellForReuse() {
        cell = nil
    }
}
