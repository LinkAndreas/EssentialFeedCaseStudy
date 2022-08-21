//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialApp
import EssentialFeed
import EssentialFeediOS
import XCTest

final class FeedUIIntegrationTests: XCTestCase {
    func test_feedView_hasTitle() {
        let (_, sut) = makeSUT()

        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.title, feedTitle)
    }

    func test_imageSelection_notifiesHandler() {
        let image0 = makeImage()
        let image1 = makeImage()
        var imageSelection: [FeedImage] = []

        let (loaderSpy, sut) = makeSUT(selection: { image in
            imageSelection.append(image)
        })

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: [image0, image1])

        sut.simulateTapOnFeedImage(at: 0)
        XCTAssertEqual(imageSelection, [image0])

        sut.simulateTapOnFeedImage(at: 1)
        XCTAssertEqual(imageSelection, [image0, image1])
    }

    func test_loadFeedActions_requestsFeedFromLoader() {
        let (loaderSpy, sut) = makeSUT()

        XCTAssertEqual(loaderSpy.loadFeedCallCount, 0, "Expected no loading requests before view is loaded")

        sut.loadViewIfNeeded()
        XCTAssertEqual(loaderSpy.loadFeedCallCount, 1, "Expected a loading request once the view is loaded")

        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loaderSpy.loadFeedCallCount, 2, "Expected another load request once user initiated the load")

        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loaderSpy.loadFeedCallCount, 3, "Expected a third load request once user initiated another load")
    }

    func test_loadMoreActions_requestsMoreFromLoader() {
        let (loaderSpy, sut) = makeSUT()
        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading()

        XCTAssertEqual(loaderSpy.loadMoreCallCount, 0, "Expected no requests until load more action")

        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(loaderSpy.loadMoreCallCount, 1, "Expected load more request")

        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(loaderSpy.loadMoreCallCount, 1, "Expected no request while loading")

        loaderSpy.completeLoadMore(lastPage: false, at: 0)
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(loaderSpy.loadMoreCallCount, 2, "Expected request after load more completed with more pages.")

        loaderSpy.completeLoadMoreWithError(at: 1)
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(loaderSpy.loadMoreCallCount, 3, "Expected request after load more completed with error.")

        loaderSpy.completeLoadMore(lastPage: true, at: 2)
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(loaderSpy.loadMoreCallCount, 3, "Expected no request after load more completed with no more pages.")
    }

    func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")

        loaderSpy.completeFeedLoading(with: [], at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading is completed")

        sut.simulateUserInitiatedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiated load")

        loaderSpy.completeFeedLoadingWithError(anyNSError(), at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user initiated load failed")
    }

    func test_loadingMoreIndicator_isVisibleWhileLoadingMore() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertFalse(sut.isShowingLoadingMoreIndicator, "Expected no loading indicator once view is loaded")

        loaderSpy.completeFeedLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingMoreIndicator, "Expected no loading indicator once loading completes successfully")

        sut.simulateLoadMoreFeedAction()
        XCTAssertTrue(sut.isShowingLoadingMoreIndicator, "Expected loading indicator on load more action")

        loaderSpy.completeLoadMore(at: 0)
        XCTAssertFalse(sut.isShowingLoadingMoreIndicator, "Expected no loading indicator once user initiated loading completes successfully")

        sut.simulateLoadMoreFeedAction()
        XCTAssertTrue(sut.isShowingLoadingMoreIndicator, "Expected loading indicator on second load more action")

        loaderSpy.completeLoadMoreWithError(at: 1)
        XCTAssertFalse(sut.isShowingLoadingMoreIndicator, "Expected no loading indicator once user initiated loading completes with error")
    }

    func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() {
        let image0 = makeImage(description: "a description", location: "a location")
        let image1 = makeImage(description: nil, location: "another location")
        let image2 = makeImage(description: "another description", location: nil)
        let image3 = makeImage(description: nil, location: nil)

        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        assertThat(sut, renders: [])

        loaderSpy.completeFeedLoading(with: [image0, image1])
        assertThat(sut, renders: [image0, image1])
        
        sut.simulateLoadMoreFeedAction()
        loaderSpy.completeLoadMore(with: [image0, image1, image2, image3])
        assertThat(sut, renders: [image0, image1, image2, image3])

        sut.simulateUserInitiatedReload()
        loaderSpy.completeFeedLoading(with: [image0, image1], at: 1)
        assertThat(sut, renders: [image0, image1])
    }

    func test_loadFeedCompletion_rendersSuccessfullyLoadedFeedAfterNonEmptyFeed() {
        let image0 = makeImage()
        let image1 = makeImage()

        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: [image0])
        assertThat(sut, renders: [image0])
        
        sut.simulateLoadMoreFeedAction()
        loaderSpy.completeLoadMore(with: [image0, image1])
        assertThat(sut, renders: [image0, image1])

        sut.simulateUserInitiatedReload()
        loaderSpy.completeFeedLoading(with: [], at: 1)
        assertThat(sut, renders: [])
    }

    func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let image0 = makeImage(description: "a description", location: "a location")
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: [image0])
        assertThat(sut, renders: [image0])

        sut.simulateUserInitiatedReload()
        loaderSpy.completeFeedLoadingWithError(anyNSError(), at: 1)
        assertThat(sut, renders: [image0])
        
        sut.simulateLoadMoreFeedAction()
        loaderSpy.completeLoadMoreWithError()
        assertThat(sut, renders: [image0])
    }

    func test_feedImageView_loadsImageURLWhenVisible() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)

        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: [image0, image1])

        XCTAssertEqual(loaderSpy.loadedImageURLs, [], "Expected no image URL requests until views become visible")

        sut.simulateFeedImageViewVisible(at: 0)

        XCTAssertEqual(loaderSpy.loadedImageURLs, [image0.url], "Expected first image URL request once first view becomes visible")

        sut.simulateFeedImageViewVisible(at: 1)

        XCTAssertEqual(loaderSpy.loadedImageURLs, [image0.url, image1.url], "Expected second image URL request once second view becomes visible")
    }

    func test_feedImageView_cancelsFeedImageLoadingWhenNotVisibleAnymore() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-0.com")!)

        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: [image0, image1])

        XCTAssertEqual(loaderSpy.cancelledImageURLs, [], "Expected no image URL requests until views become visible")

        sut.simulateFeedImageViewNotVisible(at: 0)

        XCTAssertEqual(loaderSpy.cancelledImageURLs, [image0.url], "Expected on cancelled image URL request once first view is not visible anymore")

        sut.simulateFeedImageViewNotVisible(at: 1)

        XCTAssertEqual(loaderSpy.cancelledImageURLs, [image0.url, image1.url], "Expected two cancelled image URL requests once second view is not visible anymore")
    }

    func test_feedImageViewLoadingIndicator_isVisibleWhileLoadingImage() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: [makeImage(), makeImage()])

        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)

        XCTAssertEqual(view0?.isShowingLoadingIndicator, true, "Expected loading indicator for first view while loading first image")
        XCTAssertEqual(view1?.isShowingLoadingIndicator, true, "Expected loading indicator for second view while loading second image")

        loaderSpy.completeImageLoading(with: .success(anyData()), at: 0)
        XCTAssertEqual(view0?.isShowingLoadingIndicator, false, "Expected no loading indicator for first view when loading first image completes successfully")
        XCTAssertEqual(view1?.isShowingLoadingIndicator, true, "Expected no loading indicator state change for second view once first image loading completes successfully")

        loaderSpy.completeImageLoading(with: .failure(anyNSError()), at: 1)
        XCTAssertEqual(view0?.isShowingLoadingIndicator, false, "Expected no loading indicator state change for first view once second image loading completes successfully")
        XCTAssertEqual(view1?.isShowingLoadingIndicator, false, "Expected no loading indicator for second view when loading second image completes with error")
    }

    func test_feedImageView_rendersImageDataLoadedFromURL() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: [makeImage(), makeImage()])

        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)

        XCTAssertEqual(view0?.renderedImage, .none, "Expected no image when loading first image")
        XCTAssertEqual(view1?.renderedImage, .none, "Expected no image when loading second image")

        let imageData0 = UIImage.make(with: .blue).pngData()!
        let imageData1 = UIImage.make(with: .red).pngData()!
        loaderSpy.completeImageLoading(with: .success(imageData0), at: 0)
        XCTAssertEqual(view0?.renderedImage, imageData0, "Expected image for first view when loading first image completed successfully")
        XCTAssertEqual(view1?.renderedImage, .none, "Expected no image state change for second view when first image loading completed successfully")

        loaderSpy.completeImageLoading(with: .success(imageData1), at: 1)
        XCTAssertEqual(view0?.renderedImage, imageData0, "Expected no image state change for first view when second image loading completed with error")
        XCTAssertEqual(view1?.renderedImage, imageData1, "Expected image for second view when loading second image completes successfully")
    }

    func test_feedImageViewRetryButton_isVisibleOnImageURLoadError() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: [makeImage(), makeImage()])

        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)

        XCTAssertEqual(view0?.isShowingRetryAction, false, "Expected no retry when loading first image")
        XCTAssertEqual(view1?.isShowingRetryAction, false, "Expected no retry when loading second image")

        let imageData0 = UIImage.make(with: .blue).pngData()!
        loaderSpy.completeImageLoading(with: .success(imageData0), at: 0)
        XCTAssertEqual(view0?.isShowingRetryAction, false, "Expected no retry for first image when loading first image completed successfully")
        XCTAssertEqual(view1?.isShowingRetryAction, false, "Expected no retry state change for second view when first image loading completed successfully")

        loaderSpy.completeImageLoading(with: .failure(anyNSError()), at: 1)
        XCTAssertEqual(view0?.isShowingRetryAction, false, "Expected no image state change for first view when second image loading completed with error")
        XCTAssertEqual(view1?.isShowingRetryAction, true, "Expected retry for second view when loading second image completed with an error")
    }

    func test_feedImageViewRetryButton_isVisibleOnInvalidImageData() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: [makeImage(), makeImage()])

        let view0 = sut.simulateFeedImageViewVisible(at: 0)

        XCTAssertEqual(view0?.isShowingRetryAction, false, "Expected no retry when loading first image")

        let invalidImageData = "Invalid Image data".data(using: .utf8)!
        loaderSpy.completeImageLoading(with: .success(invalidImageData), at: 0)
        XCTAssertEqual(view0?.isShowingRetryAction, true, "Expected retry for first image when loading first image completed with invalid data")
    }

    func test_feedImageViewRetryAction_retriesImageLoad() {
        let image0 = makeImage(url: URL(string: "htttp://url-0.com")!)
        let image1 = makeImage(url: URL(string: "htttp://url-1.com")!)
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: [image0, image1])

        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)

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
        loaderSpy.completeFeedLoading(with: [image0, image1])

        sut.simulateFeedImageViewNearVisible(at: 0)
        XCTAssertEqual(loaderSpy.loadedImageURLs, [image0.url], "Expected first image URL request once first image is near visible")

        sut.simulateFeedImageViewNearVisible(at: 1)
        XCTAssertEqual(loaderSpy.loadedImageURLs, [image0.url, image1.url], "Expected second image URL request once second image is near visible")
    }

    func test_feedImageview_cancelsImageURLPreloadingWhenNotNearVisibleAnymore() {
        let image0 = makeImage(url: URL(string: "htttp://url-0.com")!)
        let image1 = makeImage(url: URL(string: "htttp://url-1.com")!)
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: [image0, image1])
        XCTAssertEqual(loaderSpy.cancelledImageURLs, [], "Expected no cancelled image URL requests until image is not near visible")

        sut.simulateFeedImageViewNotNearVisible(at: 0)
        XCTAssertEqual(loaderSpy.cancelledImageURLs, [image0.url], "Expected first cancelled image URL request once first image is not near visible anymore")

        sut.simulateFeedImageViewNotNearVisible(at: 1)
        XCTAssertEqual(loaderSpy.cancelledImageURLs, [image0.url, image1.url], "Expected second cancelled image URL request once second image is not near visible anymore")
    }

    func test_feedImageView_doesNotRenderLoadedImageWhenNotVisibleAnymore() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: [makeImage()])

        let view = sut.simulateFeedImageViewNotVisible()
        loaderSpy.completeImageLoading(with: .success(anyImageData()))

        XCTAssertNil(view?.renderedImage, "Expected no rendered imagewhen an image load completes after the view s not visible anymore.")
    }

    func test_loadFeedCompletion_dispatchesFromBackgroundToMainThread() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()

        let exp = expectation(description: "Wait for background queue.")

        DispatchQueue.global().async {
            loaderSpy.completeFeedLoading(with: [], at: 0)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadMoreCompletion_dispatchesFromBackgroundToMainThread() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading()
        sut.simulateLoadMoreFeedAction()

        let exp = expectation(description: "Wait for background queue.")

        DispatchQueue.global().async {
            loaderSpy.completeLoadMore()
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_loadFeedImageCompletion_dispatchesFromBackgroundToMainThread() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading(with: [makeImage()], at: 0)
        _ = sut.simulateFeedImageViewVisible(at: 0)

        let exp = expectation(description: "Wait for background queue.")

        DispatchQueue.global().async {
            loaderSpy.completeImageLoading(with: .success(self.anyImageData()), at: 0)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadMoreCompletion_rendersErrorMessageOnError() {
        let (loaderSpy, sut) = makeSUT()
        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading()
        sut.simulateLoadMoreFeedAction()
        
        XCTAssertNil(sut.loadMoreFeedErrorMessage)
        
        loaderSpy.completeLoadMoreWithError()
        
        XCTAssertEqual(sut.loadMoreFeedErrorMessage, loadError)
        
        sut.simulateLoadMoreFeedAction()
        
        XCTAssertNil(sut.loadMoreFeedErrorMessage)
    }

    func test_loadFeedCompletion_rendersConnectionErrorUntilUserInitiatedReloadSucceeded() {
        let (loaderSpy, sut) = makeSUT()

        XCTAssertEqual(sut.errorMessage, .none)

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)

        sut.simulateUserInitiatedReload()
        loaderSpy.completeFeedLoading(with: [makeImage()], at: 1)
        XCTAssertEqual(sut.errorMessage, .none)
    }

    func test_errorView_dismissesErrorMessageOnTap() {
        let (loaderSpy, sut) = makeSUT()

        XCTAssertEqual(sut.errorMessage, .none)

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)

        sut.simulateErrorMessageButtonTap()
        XCTAssertEqual(sut.errorMessage, .none)
    }
    
    func test_loadMoreView_dismissesErrorMessageOnTap() {
        let (loaderSpy, sut) = makeSUT()
        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoading()
        
        sut.simulateLoadMoreFeedAction()
        
        XCTAssertEqual(loaderSpy.loadMoreCallCount, 1)
        
        sut.simulateTapOnLoadMoreErrorMessage()

        XCTAssertEqual(loaderSpy.loadMoreCallCount, 1)

        loaderSpy.completeLoadMoreWithError()
        
        XCTAssertEqual(sut.loadMoreFeedErrorMessage, loadError)

        sut.simulateTapOnLoadMoreErrorMessage()

        XCTAssertEqual(loaderSpy.loadMoreCallCount, 2)
    }
}

extension FeedUIIntegrationTests {
    private func makeSUT(
        selection: @escaping (FeedImage) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (loaderSpy: LoaderSpy, sut: ListViewController) {
        let loaderSpy = LoaderSpy()
        let sut = FeedUIComposer.feedComposedWith(
            feedLoader: loaderSpy.loadPublisher,
            imageLoader: loaderSpy.loadPublisher(from:),
            selection: selection
        )
        trackForMemoryLeaks(loaderSpy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (loaderSpy, sut)
    }

    private func makeImage(
        description: String? = "any description",
        location: String? = nil,
        url: URL = .init(string: "http://any-url.com")!
    ) -> FeedImage {
        return FeedImage(id: UUID(), description: description, location: location, url: url)
    }

    private func anyImageData() -> Data {
        return UIImage.make(with: .red).pngData()!
    }
}
