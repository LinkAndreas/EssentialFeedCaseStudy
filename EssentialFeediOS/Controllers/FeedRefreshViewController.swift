//  Copyright © 2021 Andreas Link. All rights reserved.

import UIKit

final class FeedRefreshViewController: NSObject, FeedLoadingView {
    private let presenter: FeedPresenter

    private (set) lazy var view: UIRefreshControl = loadView()

    init(presenter: FeedPresenter) {
        self.presenter = presenter

        super.init()
    }

    @objc
    func refresh() {
        presenter.refresh()
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
