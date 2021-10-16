//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class RemoteImageDataLoader {
    let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func loadImageData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        client.load(from: url) { result in
            completion(.failure(anyNSError()))
        }
    }
}

final class LoadFeedImageDataFromRemoteUseCaseTests: XCTestCase {
    func test_init_doesNotRequestAnyURL() {
        let (spy, _) = makeSUT()

        XCTAssertEqual(spy.requestedURLs, [], "Requested URLs must be empty.")
    }

    func test_loadImageDataFromURL_requestsImageDataFromURL() {
        let url = anyURL()
        let (spy, sut) = makeSUT()

        sut.loadImageData(from: url) { _ in }

        XCTAssertEqual(spy.requestedURLs, [url])
    }

    func test_loadImageDataFromURLTwice_requestsImageDataFromURLTwice() {
        let url = anyURL()
        let (spy, sut) = makeSUT()

        sut.loadImageData(from: url) { _ in }
        sut.loadImageData(from: url) { _ in }

        XCTAssertEqual(spy.requestedURLs, [url, url])
    }

    func test_loadImageDataFromURL_deliversErrorOnClientError() {
        let (spy, sut) = makeSUT()
        let error = anyNSError()

        expect(sut, toCompleteWith: .failure(error), when: {
            spy.complete(with: error)
        })
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
        toCompleteWith expectedResult: Result<Data, Error>,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let url = anyURL()
        let exp = expectation(description: "Wait for load completion")
        var receivedResult: Result<Data, Error>?
        sut.loadImageData(from: url) { result in
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
