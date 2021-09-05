//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import EssentialFeediOS
import XCTest

final class FeedUIIntegrationTests: XCTestCase {
    func test_feedView_hasTitle() {
        let (_, sut) = makeSUT()

        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.title, localized("FEED_VIEW_TITLE"))
    }

    func test_loadFeedActions_requestsFeedFromLoader() {
        let (loaderSpy, sut) = makeSUT()

        XCTAssertEqual(loaderSpy.loadFeedCallCount, 0, "Expected no loading requests before view is loaded")

        sut.loadViewIfNeeded()
        XCTAssertEqual(loaderSpy.loadFeedCallCount, 1, "Expected a loading request once the view is loaded")

        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loaderSpy.loadFeedCallCount, 2, "Expected another load request once user initiated the load")

        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loaderSpy.loadFeedCallCount, 3, "Expected a third load request once user initiated another load")
    }

    func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")

        loaderSpy.completeFeedLoading(with: .success([]), atIndex: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading is completed")

        sut.simulateUserInitiatedFeedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiated load")

        loaderSpy.completeFeedLoading(with: .failure(anyNSError()), atIndex: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user initiated load failed")
    }

    func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() {
        let image0 = makeImage(description: "a description", location: "a location")
        let image1 = makeImage(description: nil, location: "another location")
        let image2 = makeImage(description: "another description", location: nil)
        let image3 = makeImage(description: nil, location: nil)

        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()

        assertThat(sut, renders: [])

        loaderSpy.completeFeedLoading(with: .success([image0]))

        assertThat(sut, renders: [image0])

        sut.simulateUserInitiatedFeedReload()

        loaderSpy.completeFeedLoading(with: .success([image0, image1, image2, image3]), atIndex: 1)

        assertThat(sut, renders: [image0, image1, image2, image3])
    }

    func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let image0 = makeImage(description: "a description", location: "a location")
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()

        loaderSpy.completeFeedLoading(with: .success([image0]))

        assertThat(sut, renders: [image0])

        sut.simulateUserInitiatedFeedReload()

        loaderSpy.completeFeedLoading(with: .failure(anyNSError()), atIndex: 1)

        assertThat(sut, renders: [image0])
    }

    func test_feedImageView_loadsImageURLWhenVisible() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)

        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: .success([image0, image1]))

        XCTAssertEqual(loaderSpy.loadedImageURLs, [], "Expected no image URL requests until views become visible")

        sut.simulateFeedImageViewVisible(atIndex: 0)

        XCTAssertEqual(loaderSpy.loadedImageURLs, [image0.url], "Expected first image URL request once first view becomes visible")

        sut.simulateFeedImageViewVisible(atIndex: 1)

        XCTAssertEqual(loaderSpy.loadedImageURLs, [image0.url, image1.url], "Expected second image URL request once second view becomes visible")
    }

    func test_feedImageView_cancelsFeedImageLoadingWhenNotVisibleAnymore() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-0.com")!)

        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: .success([image0, image1]))

        XCTAssertEqual(loaderSpy.cancelledImageURLs, [], "Expected no image URL requests until views become visible")

        sut.simulateFeedImageViewNotVisible(atIndex: 0)

        XCTAssertEqual(loaderSpy.cancelledImageURLs, [image0.url], "Expected on cancelled image URL request once first view is not visible anymore")

        sut.simulateFeedImageViewNotVisible(atIndex: 1)

        XCTAssertEqual(loaderSpy.cancelledImageURLs, [image0.url, image1.url], "Expected two cancelled image URL requests once second view is not visible anymore")
    }

    func test_feedImageViewLoadingIndicator_isVisibleWhileLoadingImage() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: .success([makeImage(), makeImage()]))

        let view0 = sut.simulateFeedImageViewVisible(atIndex: 0)
        let view1 = sut.simulateFeedImageViewVisible(atIndex: 1)

        XCTAssertEqual(view0?.isShowingLoadingIndicator, true, "Expected loading indicator for first view while loading first image")
        XCTAssertEqual(view1?.isShowingLoadingIndicator, true, "Expected loading indicator for second view while loading second image")

        loaderSpy.completeImageLoading(with: .success(anyData()), atIndex: 0)
        XCTAssertEqual(view0?.isShowingLoadingIndicator, false, "Expected no loading indicator for first view when loading first image completes successfully")
        XCTAssertEqual(view1?.isShowingLoadingIndicator, true, "Expected no loading indicator state change for second view once first image loading completes successfully")

        loaderSpy.completeImageLoading(with: .failure(anyNSError()), atIndex: 1)
        XCTAssertEqual(view0?.isShowingLoadingIndicator, false, "Expected no loading indicator state change for first view once second image loading completes successfully")
        XCTAssertEqual(view1?.isShowingLoadingIndicator, false, "Expected no loading indicator for second view when loading second image completes with error")
    }

    func test_feedImageView_rendersImageDataLoadedFromURL() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: .success([makeImage(), makeImage()]))

        let view0 = sut.simulateFeedImageViewVisible(atIndex: 0)
        let view1 = sut.simulateFeedImageViewVisible(atIndex: 1)

        XCTAssertEqual(view0?.renderedImage, .none, "Expected no image when loading first image")
        XCTAssertEqual(view1?.renderedImage, .none, "Expected no image when loading second image")

        let imageData0 = UIImage.make(with: .blue).pngData()!
        let imageData1 = UIImage.make(with: .red).pngData()!
        loaderSpy.completeImageLoading(with: .success(imageData0), atIndex: 0)
        XCTAssertEqual(view0?.renderedImage, imageData0, "Expected image for first view when loading first image completed successfully")
        XCTAssertEqual(view1?.renderedImage, .none, "Expected no image state change for second view when first image loading completed successfully")

        loaderSpy.completeImageLoading(with: .success(imageData1), atIndex: 1)
        XCTAssertEqual(view0?.renderedImage, imageData0, "Expected no image state change for first view when second image loading completed with error")
        XCTAssertEqual(view1?.renderedImage, imageData1, "Expected image for second view when loading second image completes successfully")
    }

    func test_feedImageViewRetryButton_isVisibleOnImageURLoadError() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: .success([makeImage(), makeImage()]))

        let view0 = sut.simulateFeedImageViewVisible(atIndex: 0)
        let view1 = sut.simulateFeedImageViewVisible(atIndex: 1)

        XCTAssertEqual(view0?.isShowingRetryAction, false, "Expected no retry when loading first image")
        XCTAssertEqual(view1?.isShowingRetryAction, false, "Expected no retry when loading second image")

        let imageData0 = UIImage.make(with: .blue).pngData()!
        loaderSpy.completeImageLoading(with: .success(imageData0), atIndex: 0)
        XCTAssertEqual(view0?.isShowingRetryAction, false, "Expected no retry for first image when loading first image completed successfully")
        XCTAssertEqual(view1?.isShowingRetryAction, false, "Expected no retry state change for second view when first image loading completed successfully")

        loaderSpy.completeImageLoading(with: .failure(anyNSError()), atIndex: 1)
        XCTAssertEqual(view0?.isShowingRetryAction, false, "Expected no image state change for first view when second image loading completed with error")
        XCTAssertEqual(view1?.isShowingRetryAction, true, "Expected retry for second view when loading second image completed with an error")
    }

    func test_feedImageViewRetryButton_isVisibleOnInvalidImageData() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: .success([makeImage(), makeImage()]))

        let view0 = sut.simulateFeedImageViewVisible(atIndex: 0)

        XCTAssertEqual(view0?.isShowingRetryAction, false, "Expected no retry when loading first image")

        let invalidImageData = "Invalid Image data".data(using: .utf8)!
        loaderSpy.completeImageLoading(with: .success(invalidImageData), atIndex: 0)
        XCTAssertEqual(view0?.isShowingRetryAction, true, "Expected retry for first image when loading first image completed with invalid data")
    }

    func test_feedImageViewRetryAction_retriesImageLoad() {
        let image0 = makeImage(url: URL(string: "htttp://url-0.com")!)
        let image1 = makeImage(url: URL(string: "htttp://url-1.com")!)
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: .success([image0, image1]))

        let view0 = sut.simulateFeedImageViewVisible(atIndex: 0)
        let view1 = sut.simulateFeedImageViewVisible(atIndex: 1)

        XCTAssertEqual(loaderSpy.loadedImageURLs, [image0.url, image1.url], "Expected only two image URL requests before retry action")

        view0?.simulateRetryAction()

        XCTAssertEqual(loaderSpy.loadedImageURLs, [image0.url, image1.url, image0.url], "Expected third imageURL request after first view retry action")

        view1?.simulateRetryAction()

        XCTAssertEqual(loaderSpy.loadedImageURLs, [image0.url, image1.url, image0.url, image1.url], "Expected forth imageURL request after second view retry action")
    }

    func test_feedImageview_preloadsImageURLWhenNearVisible() {
        let image0 = makeImage(url: URL(string: "htttp://url-0.com")!)
        let image1 = makeImage(url: URL(string: "htttp://url-1.com")!)
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: .success([image0, image1]))

        sut.simulateFeedImageViewNearVisible(atIndex: 0)
        XCTAssertEqual(loaderSpy.loadedImageURLs, [image0.url], "Expected first image URL request once first image is near visible")

        sut.simulateFeedImageViewNearVisible(atIndex: 1)
        XCTAssertEqual(loaderSpy.loadedImageURLs, [image0.url, image1.url], "Expected second image URL request once second image is near visible")
    }

    func test_feedImageview_cancelsImageURLPreloadingWhenNotNearVisibleAnymore() {
        let image0 = makeImage(url: URL(string: "htttp://url-0.com")!)
        let image1 = makeImage(url: URL(string: "htttp://url-1.com")!)
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: .success([image0, image1]))
        XCTAssertEqual(loaderSpy.cancelledImageURLs, [], "Expected no cancelled image URL requests until image is not near visible")

        sut.simulateFeedImageViewNotNearVisible(atIndex: 0)
        XCTAssertEqual(loaderSpy.cancelledImageURLs, [image0.url], "Expected first cancelled image URL request once first image is not near visible anymore")

        sut.simulateFeedImageViewNotNearVisible(atIndex: 1)
        XCTAssertEqual(loaderSpy.cancelledImageURLs, [image0.url, image1.url], "Expected second cancelled image URL request once second image is not near visible anymore")
    }

    func test_feedImageView_doesNotRenderLoadedImageWhenNotVisibleAnymore() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: .success([makeImage()]))

        let view = sut.simulateFeedImageViewNotVisible()
        loaderSpy.completeImageLoading(with: .success(anyImageData()))

        XCTAssertNil(view?.renderedImage, "Expected no rendered imagewhen an image load completes after the view s not visible anymore.")
    }

    func test_loadFeedCompletion_dispatchesFromBackgroundToMainThread() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()

        let exp = expectation(description: "Wait for background queue.")

        DispatchQueue.global().async {
            loaderSpy.completeFeedLoading(with: .success([]), atIndex: 0)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (loaderSpy: LoaderSpy, sut: FeedViewController) {
        let loaderSpy = LoaderSpy()
        let sut = FeedUIComposer.feedComposedWith(feedLoader: loaderSpy, imageLoader: loaderSpy)
        trackForMemoryLeaks(loaderSpy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (loaderSpy, sut)
    }

    private func makeImage(
        description: String? = "any description",
        location: String? = nil,
        url: URL = .init(string: "http://any-url.com")!
    ) -> FeedImage {
        return .init(id: UUID(), description: description, location: location, url: url)
    }

    private func anyImageData() -> Data {
        return UIImage.make(with: .red).pngData()!
    }
}
