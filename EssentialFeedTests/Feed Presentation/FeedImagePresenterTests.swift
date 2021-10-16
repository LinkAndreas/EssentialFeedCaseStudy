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
    private let imageTransformer: (Data) -> Image

    init(view: View, imageTransformer: @escaping (Data) -> Image) {
        self.view = view
        self.imageTransformer = imageTransformer
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

    func didFinishLoadingImageData(with data: Data, for model: FeedImage) {
        view.display(
            model: FeedImageViewModel(
                description: model.description,
                location: model.location,
                image: imageTransformer(data),
                isLoading: false,
                shouldRetry: false
            )
        )
    }
}

final class FeedImagePresenterTests: XCTestCase {
    func test_init_doesNotSendMessageToView() {
        let (view, _) = makeSUT()

        XCTAssertEqual(view.messages, [], "Expect no view messages")
    }

    func test_didStartLoadingImageData_displaysLoadingImage() {
        let image = anyFeedImage()
        let (view, presenter) = makeSUT()

        presenter.didStartLoadingImageData(for: image)

        let message = view.messages.first
        XCTAssertEqual(view.messages.count, 1)
        XCTAssertEqual(message?.description, image.description)
        XCTAssertEqual(message?.location, image.location)
        XCTAssertEqual(message?.image, nil)
        XCTAssertEqual(message?.isLoading, true)
        XCTAssertEqual(message?.shouldRetry, false)
    }

    func test_didFinishLoadingImageData_displaysImageOnSuccessfulTransformation() {
        let image = anyFeedImage()
        let data = anyData()
        let transformedData = AnyImage()
        let (view, presenter) = makeSUT()

        presenter.didFinishLoadingImageData(with: data, for: image)

        let message = view.messages.first
        XCTAssertEqual(view.messages.count, 1)
        XCTAssertEqual(message?.description, image.description)
        XCTAssertEqual(message?.location, image.location)
        XCTAssertEqual(message?.image, transformedData)
        XCTAssertEqual(message?.isLoading, false)
        XCTAssertEqual(message?.shouldRetry, false)
    }

    // MARK: - Helpers

    struct AnyImage: Hashable {}

    private func anyFeedImage(description: String = "anyDescription", location: String = "anyLocation") -> FeedImage {
        return .init(id: UUID(), description: description, location: location, url: anyURL())
    }

    private func makeSUT(
        imageTransformer: @escaping (Data) -> AnyImage = { data in AnyImage() },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (ViewSpy, FeedImagePresenter<ViewSpy, AnyImage>) {
        let view = ViewSpy()
        let sut = FeedImagePresenter<ViewSpy, AnyImage>(view: view, imageTransformer: imageTransformer)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (view, sut)
    }

    final class ViewSpy: FeedImageView {
        typealias Image = AnyImage

        var messages: Set<FeedImageViewModel<AnyImage>> = []

        func display(model: FeedImageViewModel<AnyImage>) {
            messages.insert(model)
        }
    }
}
