//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class RemoteImageDataLoader {
    enum Error: Swift.Error {
        case invalidData
    }

    typealias Result = Swift.Result<Data, Swift.Error>

    let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func loadImageData(from url: URL, completion: @escaping (Result) -> Void) {
        client.load(from: url) { result in
            switch result {
            case let .success((data, response)) where response.statusCode == 200 && data.isEmpty:
                completion(.failure(Error.invalidData))

            case let .success(data, response) where response.statusCode != 200:
                completion(.failure(Error.invalidData))

            case let .failure(error):
                completion(.failure(error))

            default:
                break
            }
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

    func test_loadImageDataFromURL_deliversInvalidDataErrorOnNon200HTTPResponse() {
        let (spy, sut) = makeSUT()
        let data = anyData()

        expect(sut, toCompleteWith: .failure(RemoteImageDataLoader.Error.invalidData), when: {
            spy.complete(withStatusCode: 243, data: data)
        })
    }

    func test_loadImageDataFromURL_deliversInvalidDataErrorOnEmpty200HTTPResponse() {
        let (spy, sut) = makeSUT()
        let data = Data()

        expect(sut, toCompleteWith: .failure(RemoteImageDataLoader.Error.invalidData), when: {
            spy.complete(withStatusCode: 200, data: data)
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
        toCompleteWith expectedResult: RemoteImageDataLoader.Result,
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
