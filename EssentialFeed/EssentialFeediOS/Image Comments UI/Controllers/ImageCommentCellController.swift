//  Copyright © 2022 Andreas Link. All rights reserved.

import EssentialFeed
import UIKit

public final class ImageCommentCellController: NSObject, UITableViewDataSource {
    private let viewModel: ImageCommentViewModel

    public init(viewModel: ImageCommentViewModel) {
        self.viewModel = viewModel
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ImageCommentCell = tableView.dequeueReusableCell()
        cell.usernameLabel.text = viewModel.username
        cell.dateLabel.text = viewModel.date
        cell.messageLabel.text = viewModel.message
        return cell
    }
}
