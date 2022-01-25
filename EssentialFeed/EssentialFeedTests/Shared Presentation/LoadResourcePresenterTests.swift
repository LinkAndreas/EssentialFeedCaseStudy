//  Copyright © 2022 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class LoadResourcePresenterTests: XCTestCase {
    func test_init_doesNotSendMessagesToView() {
        let (_, spy) = makeSUT()

        XCTAssertEqual(spy.receivedMessages, [])
    }

    func test_didStartLoading_displaysNoErrorMessageAndStartsLoading() {
        let (sut, spy) = makeSUT()

        sut.didStartLoading()

        XCTAssertEqual(spy.receivedMessages, [
            .display(errorMessage: .none),
            .display(isLoading: true)
        ])
    }

    func test_didStopLoading_displaysResourceAndStopsLoading() {
        let (sut, spy) = makeSUT(mapper: { resource in "\(resource) view model" })
        let resource = "resource"

        sut.didStopLoading(with: resource)

        XCTAssertEqual(spy.receivedMessages, [
            .display(resourceViewModel: "resource view model"),
            .display(isLoading: false)
        ])
    }

    func test_didStopLoadingWithError_displaysLocalizedErrorMessageAndStopsLoading() {
        let (sut, spy) = makeSUT()
        let error = anyNSError()

        sut.didStopLoading(with: error)

        XCTAssertEqual(spy.receivedMessages, [
            .display(errorMessage: localized("GENERIC_CONNECTION_ERROR")),
            .display(isLoading: false)
        ])
    }
}

extension LoadResourcePresenterTests {
    private typealias SUT = LoadResourcePresenter<String, ViewSpy>

    private func makeSUT(
        mapper: @escaping SUT.Mapper = { _ in "any" },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (SUT, ViewSpy) {
        let spy = ViewSpy()

        let sut = LoadResourcePresenter(
            resourceView: spy,
            loadingView: spy,
            errorView: spy,
            mapper: mapper
        )

        trackForMemoryLeaks(spy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (sut, spy)
    }

    private final class ViewSpy: ResourceView, ResourceLoadingView, ResourceErrorView {
        typealias ResourceViewModel = String

        enum Message: Hashable {
            case display(resourceViewModel: String)
            case display(isLoading: Bool)
            case display(errorMessage: String?)
        }

        private (set) var receivedMessages: Set<Message> = []

        func display(_ viewModel: String) {
            receivedMessages.insert(.display(resourceViewModel: viewModel))
        }

        func display(_ viewModel: ResourceLoadingViewModel) {
            receivedMessages.insert(.display(isLoading: viewModel.isLoading))
        }

        func display(_ viewModel: ResourceErrorViewModel) {
            receivedMessages.insert(.display(errorMessage: viewModel.message))
        }
    }

    private func localized(_ key: String, file: StaticString = #filePath, line: UInt = #line) -> String {
        let table = "Shared"
        let bundle = Bundle(for: SUT.self)
        let value = bundle.localizedString(forKey: key, value: nil, table: table)

        if value == key {
            XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
        }

        return value
    }
}
