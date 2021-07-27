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

        self.viewModel.onChange = { [weak self] model in
            guard let self = self else { return }

            switch model.state {
            case .loading:
                self.view.beginRefreshing()

            case .failed, .pending:
                self.view.endRefreshing()

            case let .loaded(feed):
                self.onRefresh?(feed)
                self.view.endRefreshing()
            }
        }
    }

    @objc
    func refresh() {
        viewModel.refresh()
    }
}
