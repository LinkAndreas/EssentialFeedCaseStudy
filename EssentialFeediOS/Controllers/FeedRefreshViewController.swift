//  Copyright © 2021 Andreas Link. All rights reserved.

import UIKit

final class FeedRefreshViewController: NSObject {
    private let viewModel: FeedViewModel

    private (set) lazy var view: UIRefreshControl = {
        let view: UIRefreshControl = .init()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()

    init(viewModel: FeedViewModel) {
        self.viewModel = viewModel

        super.init()

        self.viewModel.onIsLoadingChanged = { [weak view] isLoading in
            isLoading ? view?.beginRefreshing() : view?.endRefreshing()
        }
    }

    @objc
    func refresh() {
        viewModel.refresh()
    }
}
