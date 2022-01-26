//  Copyright © 2022 Andreas Link. All rights reserved.

import EssentialFeed
import UIKit

public final class ImageCommentCellController: CellController {
    private let viewModel: ImageCommentViewModel

    public init(viewModel: ImageCommentViewModel) {
        self.viewModel = viewModel
    }

    public func view(in tableView: UITableView) -> UITableViewCell {
        let cell: ImageCommentCell = tableView.dequeueReusableCell()
        cell.usernameLabel.text = viewModel.username
        cell.dateLabel.text = viewModel.date
        cell.messageLabel.text = viewModel.message
        return cell
    }
}
