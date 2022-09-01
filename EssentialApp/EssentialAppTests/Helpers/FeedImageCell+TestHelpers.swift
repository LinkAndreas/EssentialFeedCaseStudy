//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeediOS
import Foundation

extension FeedImageCell {
    var locationText: String? {
        locationLabel.text
    }

    var descriptionText: String? {
        descriptionLabel.text
    }

    var isShowingLocation: Bool {
        !locationContainer.isHidden
    }

    var isShowingImageLoadingIndicator: Bool {
        feedImageContainer.isShimmering
    }

    var renderedImage: Data? {
        return feedImageView.image?.pngData()
    }

    var isShowingRetryAction: Bool {
        return !feedImageRetryButton.isHidden
    }

    func simulateRetryAction() {
        feedImageRetryButton.simulateTap()
    }
}
