//  Copyright © 2021 Andreas Link. All rights reserved.

import UIKit

protocol FeedRefreshViewControllerDelegate: AnyObject {
    func didTriggerRefresh()
}

final class FeedRefreshViewController: NSObject, FeedLoadingView {
    @IBOutlet var view: UIRefreshControl?

    var delegate: FeedRefreshViewControllerDelegate?

    @IBAction func refresh() {
        delegate?.didTriggerRefresh()
    }

    func display(_ viewModel: FeedLoadingViewModel) {
        viewModel.isLoading ? view?.beginRefreshing() : view?.endRefreshing()
    }
}
