//  Copyright © 2021 Andreas Link. All rights reserved.

import XCTest

protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

protocol FeedErrorView {
    func display(_ viewModel: FeedErrorViewModel)
}

struct FeedViewModel: Equatable {}
struct FeedLoadingViewModel: Equatable {
    let isLoading: Bool
}

struct FeedErrorViewModel: Equatable {
    let message: String?

    static let noError: Self = .init(message: nil)
}

final class FeedPresenter {
    var feedView: FeedView
    var feedLoadingView: FeedLoadingView
    var feedErrorView: FeedErrorView

    init(feedView: FeedView, feedLoadingView: FeedLoadingView, feedErrorView: FeedErrorView) {
        self.feedView = feedView
        self.feedLoadingView = feedLoadingView
        self.feedErrorView = feedErrorView
    }

    func didStartLoadingFeed() {
        feedErrorView.display(.noError)
        feedLoadingView.display(FeedLoadingViewModel(isLoading: true))
    }
}

final class FeedPresenterTests: XCTestCase {
    func test_init_doesNotSendMessagesToView() {
        let (_, feedViewSpy) = makeSUT()

        XCTAssertEqual(feedViewSpy.receivedMessages, [])
    }

    func test_didStartLoadingFeed_displaysNoErrorMessageAndStartsLoading() {
        let (sut, feedViewSpy) = makeSUT()

        sut.didStartLoadingFeed()

        XCTAssertEqual(feedViewSpy.receivedMessages, [
            .display(errorMessage: .none),
            .display(isLoading: true)
        ])
    }
}

extension FeedPresenterTests {
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (FeedPresenter, FeedViewSpy) {
        let feedViewSpy = FeedViewSpy()

        let sut = FeedPresenter(
            feedView: feedViewSpy,
            feedLoadingView: feedViewSpy,
            feedErrorView: feedViewSpy
        )

        trackForMemoryLeaks(feedViewSpy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (sut, feedViewSpy)
    }

    final class FeedViewSpy: FeedView, FeedLoadingView, FeedErrorView {
        enum Message: Equatable {
            case display(FeedViewModel)
            case display(isLoading: Bool)
            case display(errorMessage: String?)
        }

        private (set) var receivedMessages: [Message] = []

        func display(_ viewModel: FeedViewModel) {
            receivedMessages.append(.display(viewModel))
        }

        func display(_ viewModel: FeedLoadingViewModel) {
            receivedMessages.append(.display(isLoading: viewModel.isLoading))
        }

        func display(_ viewModel: FeedErrorViewModel) {
            receivedMessages.append(.display(errorMessage: viewModel.message))
        }
    }
}
