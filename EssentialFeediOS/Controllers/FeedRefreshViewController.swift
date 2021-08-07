//  Copyright © 2021 Andreas Link. All rights reserved.

import UIKit

protocol FeedRefreshViewControllerDelegate: AnyObject {
    func didTriggerRefresh()
}

final class FeedRefreshViewController: NSObject, FeedLoadingView {
    private var delegate: FeedRefreshViewControllerDelegate

    private (set) lazy var view: UIRefreshControl = loadView()

    init(delegate: FeedRefreshViewControllerDelegate) {
        self.delegate = delegate

        super.init()
    }

    @objc
    func refresh() {
        delegate.didTriggerRefresh()
    }

    private func loadView() -> UIRefreshControl {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }

    func display(_ viewModel: FeedLoadingViewModel) {
        viewModel.isLoading ? view.beginRefreshing() : view.endRefreshing()
    }
}
