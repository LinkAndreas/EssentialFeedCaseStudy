//  Copyright © 2021 Andreas Link. All rights reserved.

import UIKit

final class FeedRefreshViewController: NSObject {
    private let viewModel: FeedViewModel

    private (set) lazy var view: UIRefreshControl = binded(.init())

    init(viewModel: FeedViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    @objc
    func refresh() {
        viewModel.refresh()
    }

    private func binded(_ view: UIRefreshControl) -> UIRefreshControl {
        viewModel.onIsLoadingChanged = { [weak view] isLoading in
            isLoading ? view?.beginRefreshing() : view?.endRefreshing()
        }

        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }
}
