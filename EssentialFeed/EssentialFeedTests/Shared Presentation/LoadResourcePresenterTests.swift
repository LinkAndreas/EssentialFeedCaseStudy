//  Copyright © 2022 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class LoadResourcePresenterTests: XCTestCase {
    func test_init_doesNotSendMessagesToView() {
        let (_, feedViewSpy) = makeSUT()

        XCTAssertEqual(feedViewSpy.receivedMessages, [])
    }

    func test_didStartLoading_displaysNoErrorMessageAndStartsLoading() {
        let (sut, feedViewSpy) = makeSUT()

        sut.didStartLoading()

        XCTAssertEqual(feedViewSpy.receivedMessages, [
            .display(errorMessage: .none),
            .display(isLoading: true)
        ])
    }

    func test_didStopLoadingResource_displaysResourceAndStopsLoading() {
        let (sut, feedViewSpy) = makeSUT(mapper: { resource in "\(resource) view model" })
        let resource = "resource"

        sut.didStopLoading(with: resource)

        XCTAssertEqual(feedViewSpy.receivedMessages, [
            .display(resourceViewModel: "resource view model"),
            .display(isLoading: false)
        ])
    }

    func test_didStopLoadingResourceWithError_displaysLocalizedErrorMessageAndStopsLoading() {
        let (sut, feedViewSpy) = makeSUT()
        let error = anyNSError()

        sut.didStopLoading(with: error)

        XCTAssertEqual(feedViewSpy.receivedMessages, [
            .display(errorMessage: localized("FEED_VIEW_CONNECTION_ERROR")),
            .display(isLoading: false)
        ])
    }
}

extension LoadResourcePresenterTests {
    private func makeSUT(
        mapper: @escaping LoadResourcePresenter.Mapper = { _ in "any" },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (LoadResourcePresenter, FeedViewSpy) {
        let feedViewSpy = FeedViewSpy()

        let sut = LoadResourcePresenter(
            resourceView: feedViewSpy,
            loadingView: feedViewSpy,
            errorView: feedViewSpy,
            mapper: mapper
        )

        trackForMemoryLeaks(feedViewSpy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (sut, feedViewSpy)
    }

    final class FeedViewSpy: ResourceView, FeedLoadingView, FeedErrorView {
        enum Message: Hashable {
            case display(resourceViewModel: String)
            case display(isLoading: Bool)
            case display(errorMessage: String?)
        }

        private (set) var receivedMessages: Set<Message> = []

        func display(_ viewModel: String) {
            receivedMessages.insert(.display(resourceViewModel: viewModel))
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
        let bundle = Bundle(for: LoadResourcePresenter.self)
        let value = bundle.localizedString(forKey: key, value: nil, table: table)

        if value == key {
            XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
        }

        return value
    }
}
