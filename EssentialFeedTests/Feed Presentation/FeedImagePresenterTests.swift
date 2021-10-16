//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

protocol FeedImageView {
    associatedtype Image: Hashable

    func display(model: FeedImageViewModel<Image>)
}

struct FeedImageViewModel<Image: Hashable>: Hashable {
    let description: String?
    let location: String?
    let image: Image?
    let isLoading: Bool
    let shouldRetry: Bool

    var hasLocation: Bool {
        location != nil
    }
}

final class FeedImagePresenter<View: FeedImageView, Image> where View.Image == Image {
    private let view: View

    init(view: View) {
        self.view = view
    }

    func didStartLoadingImageData(for model: FeedImage) {
        view.display(
            model: FeedImageViewModel(
                description: model.description,
                location: model.location,
                image: nil,
                isLoading: true,
                shouldRetry: false
            )
        )
    }
}

final class FeedImagePresenterTests: XCTestCase {
    func test_init_doesNotSendMessageToView() {
        let view = ViewSpy()
        _ = FeedImagePresenter(view: view)

        XCTAssertEqual(view.messages, [], "Expect no view messages")
    }

    func test_didStartLoadingImageData_displaysLoadingImage() {
        let image = anyFeedImage()
        let view = ViewSpy()
        let presenter = FeedImagePresenter(view: view)

        presenter.didStartLoadingImageData(for: image)

        let message = view.messages.first
        XCTAssertEqual(message?.description, image.description)
        XCTAssertEqual(message?.location, image.location)
        XCTAssertEqual(message?.image, nil)
        XCTAssertEqual(message?.isLoading, true)
        XCTAssertEqual(message?.shouldRetry, false)
    }

    // MARK: - Helpers

    struct AnyImage: Hashable {}

    func anyFeedImage(description: String = "anyDescription", location: String = "anyLocation") -> FeedImage {
        return .init(id: UUID(), description: description, location: location, url: anyURL())
    }

    final class ViewSpy: FeedImageView {
        typealias Image = AnyImage

        var messages: Set<FeedImageViewModel<AnyImage>> = []

        func display(model: FeedImageViewModel<AnyImage>) {
            messages.insert(model)
        }
    }
}
