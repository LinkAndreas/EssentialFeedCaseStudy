//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class LoadFeedImageDataFromRemoteUseCaseTests: XCTestCase {
    func test_init_doesNotRequestAnyURL() {
        let (spy, _) = makeSUT()

        XCTAssertEqual(spy.requestedURLs, [], "Requested URLs must be empty.")
    }

    func test_loadImageDataFromURL_requestsImageDataFromURL() {
        let url = anyURL()
        let (spy, sut) = makeSUT()

        _ = sut.loadImageData(from: url) { _ in }

        XCTAssertEqual(spy.requestedURLs, [url])
    }

    func test_loadImageDataFromURLTwice_requestsImageDataFromURLTwice() {
        let url = anyURL()
        let (spy, sut) = makeSUT()

        _ = sut.loadImageData(from: url) { _ in }
        _ = sut.loadImageData(from: url) { _ in }

        XCTAssertEqual(spy.requestedURLs, [url, url])
    }

    func test_loadImageDataFromURL_deliversConnectivityErrorOnClientError() {
        let (spy, sut) = makeSUT()
        let error = anyNSError()

        expect(sut, toCompleteWith: .failure(RemoteImageDataLoader.Error.connectivity), when: {
            spy.complete(with: error)
        })
    }

    func test_loadImageDataFromURL_deliversInvalidDataErrorOnNon200HTTPResponse() {
        let (spy, sut) = makeSUT()
        let data = anyData()

        expect(sut, toCompleteWith: .failure(RemoteImageDataLoader.Error.invalidData), when: {
            spy.complete(withStatusCode: 243, data: data)
        })
    }

    func test_loadImageDataFromURL_deliversInvalidDataErrorOnEmpty200HTTPResponse() {
        let (spy, sut) = makeSUT()
        let emptyData = Data()

        expect(sut, toCompleteWith: .failure(RemoteImageDataLoader.Error.invalidData), when: {
            spy.complete(withStatusCode: 200, data: emptyData)
        })
    }

    func test_loadImageDataFromURL_deliversReceivedDataOnNonEmpty200HTTPResponse() {
        let (spy, sut) = makeSUT()
        let nonEmptyData = "Non empty data".data(using: .utf8)!

        expect(sut, toCompleteWith: .success(nonEmptyData), when: {
            spy.complete(withStatusCode: 200, data: nonEmptyData)
        })
    }

    func test_loadImageDataFromURL_doesNotDeliverResultAfterInstanceGotDeallocated() {
        let url = anyURL()
        let data = anyData()
        let client = HttpClientSpy()
        var sut: RemoteImageDataLoader? = RemoteImageDataLoader(client: client)

        let exp = expectation(description: "Completion should not get called")
        exp.isInverted = true
        _ = sut?.loadImageData(from: url) { _ in
            exp.fulfill()
        }

        sut = nil

        client.complete(withStatusCode: 200, data: data)

        wait(for: [exp], timeout: 1.0)
    }

    func test_cancelLoadImageDataURLTask_cancelsClientURLRequest() {
        let url = anyURL()
        let (spy, sut) = makeSUT()

        let task = sut.loadImageData(from: url) { _ in }

        XCTAssertEqual(spy.cancelledURLs, [], "Expected no cancelled URLs until the task got cancelled.")

        task.cancel()

        XCTAssertEqual(spy.cancelledURLs, [url], "Expected requested URL to be cancelled after cancelling the task.")
    }

    func test_loadImageDataFromURL_doesNotDeliverResultAfterTheTaskGotCancelled() {
        let nonEmptyData = "Non empty data".data(using: .utf8)!
        let url = anyURL()
        let (spy, sut) = makeSUT()

        var receivedResults: [RemoteImageDataLoader.Result] = []
        let task = sut.loadImageData(from: url) { result in receivedResults.append(result) }

        task.cancel()

        spy.complete(withStatusCode: 404, data: anyData())
        spy.complete(withStatusCode: 200, data: nonEmptyData)
        spy.complete(with: anyNSError())

        XCTAssertTrue(receivedResults.isEmpty, "Expected not to receive any result.")
    }

    // MARK: - Helper
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (HttpClientSpy, RemoteImageDataLoader) {
        let client = HttpClientSpy()
        let sut = RemoteImageDataLoader(client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (client, sut)
    }

    private func expect(
        _ sut: RemoteImageDataLoader,
        toCompleteWith expectedResult: RemoteImageDataLoader.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let url = anyURL()
        let exp = expectation(description: "Wait for load completion")
        var receivedResult: Result<Data, Error>?

        _ = sut.loadImageData(from: url) { result in
            receivedResult = result
            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1.0)

        switch (expectedResult, receivedResult) {
        case let (.success(expectedData), .success(receivedData)):
            XCTAssertEqual(
                expectedData,
                receivedData,
                "Expected to receive \(expectedResult), but received \(String(describing: receivedResult)) instead.",
                file: file,
                line: line
            )

        case let (.failure(expectedError as NSError), .failure(receivedError as NSError)):
            XCTAssertEqual(
                expectedError,
                receivedError,
                "Expected to receive \(expectedError), but received \(receivedError) instead.",
                file: file,
                line: line
            )

        default:
            XCTFail(
                "Expected to receive \(expectedResult), but received \(String(describing: receivedResult)) instead.",
                file: file,
                line: line
            )
        }
    }
}
