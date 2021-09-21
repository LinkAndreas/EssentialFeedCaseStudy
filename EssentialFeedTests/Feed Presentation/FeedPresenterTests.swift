//  Copyright © 2021 Andreas Link. All rights reserved.

import XCTest

protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

struct FeedViewModel: Equatable {}
struct FeedLoadingViewModel: Equatable {}

final class FeedPresenter {
    var feedView: FeedView
    var feedLoadingView: FeedLoadingView

    init(feedView: FeedView, feedLoadingView: FeedLoadingView) {
        self.feedView = feedView
        self.feedLoadingView = feedLoadingView
    }
}

final class FeedPresenterTests: XCTestCase {
    func test_init_doesNotSendMessagesToView() {
        let (_, feedViewSpy, feedLoadingViewSpy) = makeSUT()

        XCTAssertEqual(feedViewSpy.receivedMessages, [])
        XCTAssertEqual(feedLoadingViewSpy.receivedMessages, [])
    }
}

extension FeedPresenterTests {
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (FeedPresenter, FeedViewSpy, FeedLoadingViewSpy) {
        let feedViewSpy = FeedViewSpy()
        let feedLoadingViewSpy = FeedLoadingViewSpy()
        let sut = FeedPresenter(feedView: feedViewSpy, feedLoadingView: feedLoadingViewSpy)
        trackForMemoryLeaks(feedViewSpy, file: file, line: line)
        trackForMemoryLeaks(feedLoadingViewSpy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, feedViewSpy, feedLoadingViewSpy)
    }

    final class FeedViewSpy: FeedView {
        enum Message: Equatable {
            case display(FeedViewModel)
        }

        var receivedMessages: [Message] = []

        func display(_ viewModel: FeedViewModel) {
            receivedMessages.append(.display(viewModel))
        }
    }

    final class FeedLoadingViewSpy: FeedLoadingView {
        enum Message: Equatable {
            case display(FeedLoadingViewModel)
        }

        var receivedMessages: [Message] = []

        func display(_ viewModel: FeedLoadingViewModel) {
            receivedMessages.append(.display(viewModel))
        }
    }
}
