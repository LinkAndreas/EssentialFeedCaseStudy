//  Copyright © 2021 Andreas Link. All rights reserved.

import XCTest
import EssentialFeed

protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

protocol FeedErrorView {
    func display(_ viewModel: FeedErrorViewModel)
}

struct FeedViewModel: Hashable {
    let feed: [FeedImage]
}

struct FeedLoadingViewModel: Equatable {
    let isLoading: Bool
}

struct FeedErrorViewModel: Equatable {
    let message: String?

    static let noError: Self = .init(message: nil)
    static func error(message: String?) -> Self {
        return .init(message: message)
    }
}

final class FeedPresenter {
    var feedView: FeedView
    var feedLoadingView: FeedLoadingView
    var feedErrorView: FeedErrorView

    private var feedLoadError: String {
        return NSLocalizedString(
            "FEED_VIEW_CONNECTION_ERROR",
            tableName: "Feed",
            bundle: Bundle(for: FeedPresenter.self),
            comment: "Error message displayed when we can't fetch the feed due to a connection error."
        )
    }

    init(feedView: FeedView, feedLoadingView: FeedLoadingView, feedErrorView: FeedErrorView) {
        self.feedView = feedView
        self.feedLoadingView = feedLoadingView
        self.feedErrorView = feedErrorView
    }

    func didStartLoadingFeed() {
        feedErrorView.display(.noError)
        feedLoadingView.display(FeedLoadingViewModel(isLoading: true))
    }

    func didStopLoadingFeed(with feed: [FeedImage]) {
        feedView.display(FeedViewModel(feed: feed))
        feedLoadingView.display(FeedLoadingViewModel(isLoading: false))
    }

    func didStopLoadingFeed(with error: Error) {
        feedErrorView.display(.error(message: feedLoadError))
        feedLoadingView.display(FeedLoadingViewModel(isLoading: false))
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

    func test_didStopLoadingFeed_displaysFeedAndStopsLoading() {
        let (sut, feedViewSpy) = makeSUT()
        let feed = uniqueImageFeed().models

        sut.didStopLoadingFeed(with: feed)

        XCTAssertEqual(feedViewSpy.receivedMessages, [
            .display(feed: feed),
            .display(isLoading: false)
        ])
    }

    func test_didStopLoadingWithError_displaysLocalizedErrorMessageAndStopsLoading() {
        let (sut, feedViewSpy) = makeSUT()
        let error = anyNSError()

        sut.didStopLoadingFeed(with: error)

        XCTAssertEqual(feedViewSpy.receivedMessages, [
            .display(errorMessage: localized("FEED_VIEW_CONNECTION_ERROR")),
            .display(isLoading: false)
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
        enum Message: Hashable {
            case display(feed: [FeedImage])
            case display(isLoading: Bool)
            case display(errorMessage: String?)
        }

        private (set) var receivedMessages: Set<Message> = []

        func display(_ viewModel: FeedViewModel) {
            receivedMessages.insert(.display(feed: viewModel.feed))
        }

        func display(_ viewModel: FeedLoadingViewModel) {
            receivedMessages.insert(.display(isLoading: viewModel.isLoading))
        }

        func display(_ viewModel: FeedErrorViewModel) {
            receivedMessages.insert(.display(errorMessage: viewModel.message))
        }
    }

    private func localized(_ key: String, file: StaticString = #filePath, line: UInt = #line) -> String {
        let table = "Feed"
        let bundle = Bundle(for: FeedPresenter.self)
        let value = bundle.localizedString(forKey: key, value: nil, table: table)

        if value == key {
            XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
        }

        return value
    }
}
