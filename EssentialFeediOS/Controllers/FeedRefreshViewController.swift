//  Copyright © 2021 Andreas Link. All rights reserved.

import UIKit

final class FeedRefreshViewController: NSObject, FeedLoadingView {
    private let onRefresh: () -> Void

    private (set) lazy var view: UIRefreshControl = loadView()

    init(onRefresh: @escaping () -> Void) {
        self.onRefresh = onRefresh

        super.init()
    }

    @objc
    func refresh() {
        onRefresh()
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
