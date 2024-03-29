//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import EssentialFeediOS
import UIKit
import XCTest

final class FeedSnapshotTests: XCTestCase {
    func test_feedWithContent() {
        let sut = makeSUT()

        sut.display(feedWithContent())

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "FEED_WITH_CONTENT_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "FEED_WITH_CONTENT_dark")
        assert(
            snapshot: sut.snapshot(for: .iPhone8(style: .light, category: .extraExtraExtraLarge)),
            named: "FEED_WITH_CONTENT_extraExtraExtraLarge_light"
        )
        assert(
            snapshot: sut.snapshot(for: .iPhone8(style: .dark, category: .extraExtraExtraLarge)),
            named: "FEED_WITH_CONTENT_extraExtraExtraLarge_dark"
        )
    }

    func test_feedWithFailedImageLoading() {
        let sut = makeSUT()

        sut.display(feedWithFailedImageLoading())

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "FEED_WITH_FAILED_IMAGE_LOADING_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "FEED_WITH_FAILED_IMAGE_LOADING_dark")
        assert(
            snapshot: sut.snapshot(for: .iPhone8(style: .light, category: .extraExtraExtraLarge)),
            named: "FEED_WITH_FAILED_IMAGE_LOADING_extraExtraExtraLarge_light"
        )
        assert(
            snapshot: sut.snapshot(for: .iPhone8(style: .dark, category: .extraExtraExtraLarge)),
            named: "FEED_WITH_FAILED_IMAGE_LOADING_extraExtraExtraLarge_dark"
        )
    }

    func test_feedWithLoadMoreIndicator() {
        let sut = makeSUT()

        sut.display(feedWithLoadMoreIndicator())

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "FEED_WITH_LOAD_MORE_INDICATOR_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "FEED_WITH_LOAD_MORE_INDICATOR_dark")
    }

    func test_feedWithLoadMoreError() {
        let sut = makeSUT()

        sut.display(feedWithLoadMoreError())

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "FEED_WITH_LOAD_MORE_ERROR_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "FEED_WITH_LOAD_MORE_ERROR_dark")
        assert(
            snapshot: sut.snapshot(for: .iPhone8(style: .light, category: .extraExtraExtraLarge)),
            named: "FEED_WITH_LOAD_MORE_ERROR_extraExtraExtraLarge_light"
        )
        assert(
            snapshot: sut.snapshot(for: .iPhone8(style: .dark, category: .extraExtraExtraLarge)),
            named: "FEED_WITH_LOAD_MORE_ERROR_extraExtraExtraLarge_dark"
        )
    }
}

private extension ListViewController {
    func display(_ stubs: [ImageStub]) {
        let cells: [CellController] = stubs.map { stub in
            let controller = FeedImageCellController(viewModel: stub.viewModel, delegate: stub)
            stub.controller = controller
            return CellController(id: UUID(), dataSource: controller, dataSourcePrefetching: controller)
        }

        display(cells)
    }
}

private extension FeedSnapshotTests {
    func makeSUT() -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! ListViewController
        controller.loadViewIfNeeded()
        controller.tableView.showsVerticalScrollIndicator = false
        controller.tableView.showsHorizontalScrollIndicator = false
        return controller
    }

    func feedWithContent() -> [ImageStub] {
        return [
            ImageStub(
                viewModel: FeedImageViewModel(
                    description: "Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
                    location: "Paris, France"
                ),
                image: UIImage.make(with: .red)
            ),
            ImageStub(
                viewModel: FeedImageViewModel(
                    description: "It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal distribution of letters, as opposed to using 'Content here, content here', making it look like readable English. Many desktop publishing packages and web page editors now use Lorem Ipsum as their default model text, and a search for 'lorem ipsum' will uncover many web sites still in their infancy.",
                    location: "Berlin, Germany"
                ),
                image: UIImage.make(with: .green)
            )
        ]
    }

    func feedWithFailedImageLoading() -> [ImageStub] {
        return [
            ImageStub(
                viewModel: FeedImageViewModel(
                    description: "Brandenburg Gate",
                    location: "Berlin, Germany"
                )
            ),
            ImageStub(
                viewModel: FeedImageViewModel(
                    description: "Eifel Tower",
                    location: "Paris, France"
                )
            )
        ]
    }

    func feedWithLoadMoreIndicator() -> [CellController] {
        let loadMore = LoadMoreCellController()
        loadMore.display(ResourceLoadingViewModel(isLoading: true))

        return feed(with: loadMore)
    }

    func feedWithLoadMoreError() -> [CellController] {
        let loadMore = LoadMoreCellController()
        loadMore.display(.error(message: "This is a multiline\nerror message"))

        return feed(with: loadMore)
    }

    func feed(with loadMore: LoadMoreCellController) -> [CellController] {
        let stub = ImageStub(
            viewModel: FeedImageViewModel(
                description: "Brandenburg Gate",
                location: "Berlin, Germany"
            )
        )
        let cellController = FeedImageCellController(viewModel: stub.viewModel, delegate: stub)
        stub.controller = cellController
        return [
            CellController(id: UUID(), dataSource: cellController, dataSourcePrefetching: cellController),
            CellController(id: UUID(), dataSource: loadMore)
        ]
    }
}

private class ImageStub: FeedImageCellControllerDelegate {
    weak var controller: FeedImageCellController?
    let viewModel: FeedImageViewModel
    let image: UIImage?

    init(viewModel: FeedImageViewModel, image: UIImage? = nil) {
        self.viewModel = viewModel
        self.image = image
    }

    func didRequestImage() {
        controller?.display(ResourceLoadingViewModel(isLoading: false))
        if let image = image {
            controller?.display(image)
            controller?.display(.noError)
        } else {
            controller?.display(.error(message: "any"))
        }
    }

    func didTriggerPreload() {}
    func didCancelLoad() {}
}
