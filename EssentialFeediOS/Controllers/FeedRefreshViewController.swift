//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import UIKit

final class FeedRefreshViewController: NSObject {
    var onRefresh: (([FeedImage]) -> Void)?

    private var feedLoader: FeedLoader?

    private (set) lazy var view: UIRefreshControl = {
        let view: UIRefreshControl = .init()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()

    init(feedLoader: FeedLoader?) {
        self.feedLoader = feedLoader
    }

    @objc
    func refresh() {
        view.beginRefreshing()
        feedLoader?.fetchFeed { [weak self] result in
            guard let self = self else { return }

            if let feed = try? result.get() {
                self.onRefresh?(feed)
            }

            self.view.endRefreshing()
        }
    }
}
