//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import UIKit

final class FeedRefreshViewController: NSObject {
    var onRefresh: (([FeedImage]) -> Void)?

    private let viewModel: FeedViewModel

    private (set) lazy var view: UIRefreshControl = {
        let view: UIRefreshControl = .init()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()

    init(feedLoader: FeedLoader) {
        self.viewModel = FeedViewModel(feedLoader: feedLoader)

        super.init()

        self.viewModel.onIsLoadingChanged = { [weak view] isLoading in
            isLoading ? view?.beginRefreshing() : view?.endRefreshing()
        }

        self.viewModel.onFeedChanged = { [weak self] feed in
            self?.onRefresh?(feed)
        }
    }

    @objc
    func refresh() {
        viewModel.refresh()
    }
}
