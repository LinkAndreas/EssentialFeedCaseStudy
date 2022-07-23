//  Copyright © 2022 Andreas Link. All rights reserved.

import EssentialFeed
import EssentialFeediOS
import XCTest

final class ImageCommentsSnapshotTests: XCTestCase {
    func test_listWithComments() {
        let sut = makeSUT()

        sut.display(comments())

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "IMAGE_COMMENTS_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "IMAGE_COMMENTS_dark")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light, category: .extraExtraExtraLarge)), named: "IMAGE_COMMENTS_extraExtraExtraLarge_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark, category: .extraExtraExtraLarge)), named: "IMAGE_COMMENTS_extraExtraExtraLarge_dark")
    }
}

extension ImageCommentsSnapshotTests {
    func makeSUT() -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "ImageComments", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! ListViewController
        controller.loadViewIfNeeded()
        controller.tableView.showsVerticalScrollIndicator = false
        controller.tableView.showsHorizontalScrollIndicator = false
        return controller
    }

    func comments() -> [ImageCommentViewModel] {
        return [
            ImageCommentViewModel(
                message: "Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
                date: "1000 years ago",
                username: "a username"
            ),
            ImageCommentViewModel(
                message: "It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal distribution of letters, as opposed to using 'Content here, content here', making it look like readable English. Many desktop publishing packages and web page editors now use Lorem Ipsum as their default model text, and a search for 'lorem ipsum' will uncover many web sites still in their infancy.",
                date: "10 days ago",
                username: "a very very long long username"
            ),
            ImageCommentViewModel(
                message: "nice",
                date: "1 hour ago",
                username: "a."
            )
        ]
    }
}

extension ListViewController {
    func display(_ comments: [ImageCommentViewModel]) {
        let controllers: [CellController] = comments.map { comment in
            let controller = ImageCommentCellController(viewModel: comment)
            return CellController(dataSource: controller)
        }

        display(controllers)
    }
}
