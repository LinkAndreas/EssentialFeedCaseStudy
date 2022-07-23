//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialApp
import EssentialFeed
import EssentialFeediOS
import XCTest

final class CommentsUIIntegrationTests: FeedUIIntegrationTests {
    func test_commentView_hasTitle() {
        let (_, sut) = makeSUT()

        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.title, commentsTitle)
    }

    func test_loadCommentsActions_requestsCommentsFromLoader() {
        let (loaderSpy, sut) = makeSUT()

        XCTAssertEqual(loaderSpy.loadCommentsCallCount, 0, "Expected no loading requests before view is loaded")

        sut.loadViewIfNeeded()
        XCTAssertEqual(loaderSpy.loadCommentsCallCount, 1, "Expected a loading request once the view is loaded")

        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loaderSpy.loadCommentsCallCount, 2, "Expected another load request once user initiated the load")

        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loaderSpy.loadCommentsCallCount, 3, "Expected a third load request once user initiated another load")
    }

    func test_loadingCommentsIndicator_isVisibleWhileLoadingComments() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")

        loaderSpy.completeCommentsLoading(with: .success([]), atIndex: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading is completed")

        sut.simulateUserInitiatedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiated load")

        loaderSpy.completeCommentsLoading(with: .failure(anyNSError()), atIndex: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user initiated load failed")
    }

    override func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() {
        let image0 = makeImage(description: "a description", location: "a location")
        let image1 = makeImage(description: nil, location: "another location")
        let image2 = makeImage(description: "another description", location: nil)
        let image3 = makeImage(description: nil, location: nil)

        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        assertThat(sut, renders: [])

        loaderSpy.completeCommentsLoading(with: .success([image0]))
        assertThat(sut, renders: [image0])

        sut.simulateUserInitiatedReload()
        loaderSpy.completeCommentsLoading(with: .success([image0, image1, image2, image3]), atIndex: 1)
        assertThat(sut, renders: [image0, image1, image2, image3])
    }

    override func test_loadFeedCompletion_rendersSuccessfullyLoadedFeedAfterNonEmptyFeed() {
        let image0 = makeImage()
        let image1 = makeImage()

        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeCommentsLoading(with: .success([image0, image1]))
        assertThat(sut, renders: [image0, image1])

        sut.simulateUserInitiatedReload()
        loaderSpy.completeCommentsLoading(with: .success([]), atIndex: 1)
        assertThat(sut, renders: [])
    }

    override func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let image0 = makeImage(description: "a description", location: "a location")
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()

        loaderSpy.completeCommentsLoading(with: .success([image0]))

        assertThat(sut, renders: [image0])

        sut.simulateUserInitiatedReload()

        loaderSpy.completeCommentsLoading(with: .failure(anyNSError()), atIndex: 1)

        assertThat(sut, renders: [image0])
    }

    override func test_loadFeedCompletion_dispatchesFromBackgroundToMainThread() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()

        let exp = expectation(description: "Wait for background queue.")

        DispatchQueue.global().async {
            loaderSpy.completeCommentsLoading(with: .success([]), atIndex: 0)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    override func test_loadFeedCompletion_rendersConnectionErrorUntilUserInitiatedReloadSucceeded() {
        let (loaderSpy, sut) = makeSUT()

        XCTAssertEqual(sut.errorMessage, .none)

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoadingWithError(atIndex: 0)
        XCTAssertEqual(sut.errorMessage, loadError)

        sut.simulateUserInitiatedReload()
        loaderSpy.completeCommentsLoading(with: .success([makeImage()]), atIndex: 1)
        XCTAssertEqual(sut.errorMessage, .none)
    }

    override func test_errorView_dismissesErrorMessageOnTap() {
        let (loaderSpy, sut) = makeSUT()

        XCTAssertEqual(sut.errorMessage, .none)

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoadingWithError(atIndex: 0)
        XCTAssertEqual(sut.errorMessage, loadError)

        sut.simulateErrorMessageButtonTap()
        XCTAssertEqual(sut.errorMessage, .none)
    }
}

extension CommentsUIIntegrationTests {
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (loaderSpy: LoaderSpy, sut: ListViewController) {
        let loaderSpy = LoaderSpy()
        let sut = CommentsUIComposer.commentsComposedWith(
            commentsLoader: loaderSpy.loadPublisher
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
        return .init(id: UUID(), description: description, location: location, url: url)
    }

    private var commentsTitle: String {
        ImageCommentsPresenter.title
    }

    private var loadError: String {
        LoadResourcePresenter<Any, DummyView>.loadError
    }

    private class DummyView: ResourceView {
        func display(_ viewModel: Any) {}
    }
}
