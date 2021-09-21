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
        let (_, feedViewSpy, feedLoadingViewSpy, feedErrorViewSpy) = makeSUT()

        XCTAssertEqual(feedViewSpy.receivedMessages, [])
        XCTAssertEqual(feedLoadingViewSpy.receivedMessages, [])
        XCTAssertEqual(feedErrorViewSpy.receivedMessages, [])
    }

    func test_didStartLoadingFeed_displaysNoErrorMessageAndStartsLoading() {
        let (sut, _, feedLoadingViewSpy, feedErrorViewSpy) = makeSUT()

        sut.didStartLoadingFeed()

        XCTAssertEqual(feedErrorViewSpy.receivedMessages, [.display(errorMessage: .none)])
        XCTAssertEqual(feedLoadingViewSpy.receivedMessages, [.display(isLoading: true)])
    }
}

extension FeedPresenterTests {
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (FeedPresenter, FeedViewSpy, FeedLoadingViewSpy, FeedErrorViewSpy) {
        let feedViewSpy = FeedViewSpy()
        let feedLoadingViewSpy = FeedLoadingViewSpy()
        let feedErrorViewSpy = FeedErrorViewSpy()

        let sut = FeedPresenter(
            feedView: feedViewSpy,
            feedLoadingView: feedLoadingViewSpy,
            feedErrorView: feedErrorViewSpy
        )

        trackForMemoryLeaks(feedViewSpy, file: file, line: line)
        trackForMemoryLeaks(feedLoadingViewSpy, file: file, line: line)
        trackForMemoryLeaks(feedErrorViewSpy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (sut, feedViewSpy, feedLoadingViewSpy, feedErrorViewSpy)
    }

    final class FeedViewSpy: FeedView {
        enum Message: Equatable {
            case display(FeedViewModel)
        }

        private (set) var receivedMessages: [Message] = []

        func display(_ viewModel: FeedViewModel) {
            receivedMessages.append(.display(viewModel))
        }
    }

    final class FeedLoadingViewSpy: FeedLoadingView {
        enum Message: Equatable {
            case display(isLoading: Bool)
        }

        private (set) var receivedMessages: [Message] = []

        func display(_ viewModel: FeedLoadingViewModel) {
            receivedMessages.append(.display(isLoading: viewModel.isLoading))
        }
    }

    final class FeedErrorViewSpy: FeedErrorView {
        enum Message: Equatable {
            case display(errorMessage: String?)
        }

        private (set) var receivedMessages: [Message] = []

        func display(_ viewModel: FeedErrorViewModel) {
            receivedMessages.append(.display(errorMessage: viewModel.message))
        }
    }
}
