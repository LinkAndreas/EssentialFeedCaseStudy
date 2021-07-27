//  Copyright © 2021 Andreas Link. All rights reserved.

import UIKit

final class FeedImageCellController {
    private let viewModel: FeedImageViewModel<UIImage>

    init(viewModel: FeedImageViewModel<UIImage>) {
        self.viewModel = viewModel
    }

    func view() -> UITableViewCell {
        let cell = binded(FeedImageCell())
        viewModel.load()
        return cell
    }

    func preload() {
        viewModel.preload()
    }

    func cancelLoad() {
        viewModel.cancelLoad()
    }

    private func binded(_ cell: FeedImageCell) -> UITableViewCell {
        cell.locationContainer.isHidden = !viewModel.hasLocation
        cell.locationLabel.text = viewModel.location
        cell.descriptionLabel.text = viewModel.description
        cell.onRetry = viewModel.load

        viewModel.onImageLoad = { [weak cell] image in
            cell?.feedImageView.image = image
        }

        viewModel.onIsRetryButtonHiddenStateChange = { [weak cell] isHidden in
            cell?.feedImageRetryButton.isHidden = isHidden
        }

        viewModel.onImageLoadingStateChange = { [weak cell] isLoading in
            isLoading ? cell?.feedImageContainer.startShimmering() : cell?.feedImageContainer.stopShimmering()
        }

        return cell
    }
}
