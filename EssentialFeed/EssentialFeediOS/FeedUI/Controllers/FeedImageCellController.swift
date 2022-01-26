//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import UIKit

public protocol FeedImageCellControllerDelegate: AnyObject {
    func didTriggerPreload()
    func didRequestImage()
    func didCancelLoad()
}

public final class FeedImageCellController: CellController, ResourceView, ResourceLoadingView, ResourceErrorView {
    public typealias ResourceViewModel = UIImage
    private let viewModel: FeedImageViewModel
    public let delegate: FeedImageCellControllerDelegate

    private var cell: FeedImageCell?

    public init(viewModel: FeedImageViewModel, delegate: FeedImageCellControllerDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
    }

    public func view(in tableView: UITableView) -> UITableViewCell {
        cell = tableView.dequeueReusableCell()
        cell?.locationContainer?.isHidden = !viewModel.hasLocation
        cell?.locationLabel?.text = viewModel.location
        cell?.descriptionLabel?.text = viewModel.description
        cell?.feedImageRetryButton.isHidden = true
        cell?.onRetry = delegate.didRequestImage
        delegate.didRequestImage()
        return cell!
    }

    public func preload() {
        delegate.didTriggerPreload()
    }

    public func cancelLoad() {
        releaseCellForReuse()
        delegate.didCancelLoad()
    }

    public func display(_ viewModel: ResourceLoadingViewModel) {
        cell?.feedImageContainer?.isShimmering = viewModel.isLoading
    }

    public func display(_ viewModel: ResourceErrorViewModel) {
        cell?.feedImageRetryButton?.isHidden = viewModel.message == nil
    }

    public func display(_ viewModel: UIImage) {
        cell?.feedImageView?.setAnimated(viewModel)
    }

    private func releaseCellForReuse() {
        cell = nil
    }
}
