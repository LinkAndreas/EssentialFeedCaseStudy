//  Copyright © 2021 Andreas Link. All rights reserved.

import UIKit

public final class FeedImageCell: UITableViewCell {
    @IBOutlet public var locationLabel: UILabel!
    @IBOutlet public var descriptionLabel: UILabel!
    @IBOutlet public var locationContainer: UIView!
    @IBOutlet public var feedImageContainer: UIView!
    @IBOutlet public var feedImageView: UIImageView!

    @IBOutlet public var feedImageRetryButton: UIButton!

    var onRetry: (() -> Void)?

    @IBAction public func didTriggerRetryButton() {
        onRetry?()
    }
}
