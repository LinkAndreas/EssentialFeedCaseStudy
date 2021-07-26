//  Copyright © 2021 Andreas Link. All rights reserved.

import UIKit

public final class FeedImageCell: UITableViewCell {
    public let locationLabel: UILabel = .init()
    public let descriptionLabel: UILabel = .init()
    public let locationContainer: UIView = .init()
    public let feedImageContainer: UIView = .init()
    public let feedImageView: UIImageView = .init()

    public private (set) lazy var feedImageRetryButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didTriggerRetryButton), for: .touchUpInside)
        return button
    }()

    var onRetry: (() -> Void)?

    @objc
    private func didTriggerRetryButton() {
        onRetry?()
    }
}
