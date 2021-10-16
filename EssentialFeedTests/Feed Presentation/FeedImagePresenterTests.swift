//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class FeedImagePresenter<View: FeedImageView, Image> where View.Image == Image {
    private let view: View
    private let imageTransformer: (Data) -> Image?

    init(view: View, imageTransformer: @escaping (Data) -> Image?) {
        self.view = view
        self.imageTransformer = imageTransformer
    }

    func didStartLoadingImageData(for model: FeedImage) {
        view.display(
            FeedImageViewModel<Image>(
                description: model.description,
                location: model.location,
                image: nil,
                isLoading: true,
                shouldRetry: false
            )
        )
    }

    func didFinishLoadingImageData(with data: Data, for model: FeedImage) {
        let image: Image? = imageTransformer(data)

        view.display(
            FeedImageViewModel<Image>(
                description: model.description,
                location: model.location,
                image: image,
                isLoading: false,
                shouldRetry: image == nil
            )
        )
    }

    func didFinishLoadingImageData(with error: NSError, for model: FeedImage) {
        view.display(
            FeedImageViewModel<Image>(
                description: model.description,
                location: model.location,
                image: nil,
                isLoading: false,
                shouldRetry: true
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

    func test_didFinishLoadingImageData_displaysRetryOnFailedTransformation() {
        let image = anyFeedImage()
        let data = anyData()
        let (view, presenter) = makeSUT(imageTransformer: failingImageTransformer)

        presenter.didFinishLoadingImageData(with: data, for: image)

        let message = view.messages.first
        XCTAssertEqual(view.messages.count, 1)
        XCTAssertEqual(message?.description, image.description)
        XCTAssertEqual(message?.location, image.location)
        XCTAssertEqual(message?.image, nil)
        XCTAssertEqual(message?.isLoading, false)
        XCTAssertEqual(message?.shouldRetry, true)
    }

    func test_didFinishLoadingImageData_displaysRetryOnError() {
        let image = anyFeedImage()
        let error = anyNSError()
        let (view, presenter) = makeSUT(imageTransformer: failingImageTransformer)

        presenter.didFinishLoadingImageData(with: error, for: image)

        let message = view.messages.first
        XCTAssertEqual(view.messages.count, 1)
        XCTAssertEqual(message?.description, image.description)
        XCTAssertEqual(message?.location, image.location)
        XCTAssertEqual(message?.image, nil)
        XCTAssertEqual(message?.isLoading, false)
        XCTAssertEqual(message?.shouldRetry, true)
    }

    // MARK: - Helpers

    struct AnyImage: Hashable {}

    private func anyFeedImage(description: String = "anyDescription", location: String = "anyLocation") -> FeedImage {
        return .init(id: UUID(), description: description, location: location, url: anyURL())
    }

    private var failingImageTransformer: (Data) -> AnyImage? = { _ in nil }

    private func makeSUT(
        imageTransformer: @escaping (Data) -> AnyImage? = { data in AnyImage() },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (ViewSpy, FeedImagePresenter<ViewSpy, AnyImage>) {
        let view = ViewSpy()
        let sut = FeedImagePresenter(view: view, imageTransformer: imageTransformer)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (view, sut)
    }

    final class ViewSpy: FeedImageView {
        typealias Image = AnyImage

        var messages: [FeedImageViewModel<AnyImage>] = []

        func display(_ model: FeedImageViewModel<AnyImage>) {
            messages.append(model)
        }
    }
}
