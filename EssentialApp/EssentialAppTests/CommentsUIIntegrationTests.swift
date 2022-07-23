//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialApp
import EssentialFeed
import EssentialFeediOS
import XCTest

final class CommentsUIIntegrationTests: XCTestCase {
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

    func test_loadCommentsCompletion_rendersSuccessfullyLoadedComments() {
        let comment0 = makeComment(message: "a message", username: "a username")
        let comment1 = makeComment(message: "another message", username: "another username")

        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        assertThat(sut, renders: [])

        loaderSpy.completeCommentsLoading(with: .success([comment0]))
        assertThat(sut, renders: [comment0])

        sut.simulateUserInitiatedReload()
        loaderSpy.completeCommentsLoading(with: .success([comment0, comment1]), atIndex: 1)
        assertThat(sut, renders: [comment0, comment1])
    }

    func test_loadCommentsCompletion_rendersSuccessfullyLoadedCommentsAfterNonEmptyComments() {
        let comment = makeComment()

        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loaderSpy.completeCommentsLoading(with: .success([comment]))
        assertThat(sut, renders: [comment])

        sut.simulateUserInitiatedReload()
        loaderSpy.completeCommentsLoading(with: .success([]), atIndex: 1)
        assertThat(sut, renders: [])
    }

    func test_loadCommentsCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let comment = makeComment(message: "a message", username: "a username")
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()

        loaderSpy.completeCommentsLoading(with: .success([comment]))

        assertThat(sut, renders: [comment])

        sut.simulateUserInitiatedReload()

        loaderSpy.completeCommentsLoading(with: .failure(anyNSError()), atIndex: 1)

        assertThat(sut, renders: [comment])
    }

    func test_loadCommentsCompletion_dispatchesFromBackgroundToMainThread() {
        let (loaderSpy, sut) = makeSUT()

        sut.loadViewIfNeeded()

        let exp = expectation(description: "Wait for background queue.")

        DispatchQueue.global().async {
            loaderSpy.completeCommentsLoading(with: .success([]), atIndex: 0)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_loadCommentsCompletion_rendersConnectionErrorUntilUserInitiatedReloadSucceeded() {
        let (loaderSpy, sut) = makeSUT()

        XCTAssertEqual(sut.errorMessage, .none)

        sut.loadViewIfNeeded()
        loaderSpy.completeFeedLoadingWithError(atIndex: 0)
        XCTAssertEqual(sut.errorMessage, loadError)

        sut.simulateUserInitiatedReload()
        loaderSpy.completeCommentsLoading(with: .success([makeComment()]), atIndex: 1)
        XCTAssertEqual(sut.errorMessage, .none)
    }

    func test_errorView_dismissesErrorMessageOnTap() {
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

    private func makeComment(
        message: String = "any message",
        username: String = "any username"
    ) -> ImageComment {
        return ImageComment(id: UUID(), message: message, createdAt: Date(), username: username)
    }
}
