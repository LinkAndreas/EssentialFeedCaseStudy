//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

class LoadFeedFromRemoteUseCaseTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let url = anyURL()
        let (_, client) = makeSut(url: url)

        XCTAssertEqual(client.requestedURLs, [])
    }

    func test_load_requestsDataFromURL() {
        let url: URL = anyURL()
        let (sut, client) = makeSut(url: url)

        sut.fetchItems { _ in }

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURLTwice() {
        let url: URL = anyURL()
        let (sut, client) = makeSut(url: url)

        sut.fetchItems { _ in }
        sut.fetchItems { _ in }

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        let url: URL = anyURL()
        let (sut, client) = makeSut(url: url)

        expect(sut: sut, toCompleteWith: failure(.connectivity), when: {
            let error = NSError(domain: "domain", code: 42, userInfo: nil)
            client.complete(with: error)
        })
    }

    func test_load_deliversErrorOnNon200HttpResponse() {
        let validJsonData: Data = makeJSONData(items: [])
        let url: URL = anyURL()
        let (sut, client) = makeSut(url: url)

        let samples: [Int] = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, statusCode in
            expect(sut: sut, toCompleteWith: failure(.invalidData), when: {
                client.complete(withStatusCode: statusCode, data: validJsonData, atIndex: index)
            })
        }
    }

    func test_load_deliversErrorOn200HttpResponseWithInvalidJson() {
        let invalidJsonData: Data = invalidJsonData()
        let url: URL = anyURL()
        let (sut, client) = makeSut(url: url)

        expect(sut: sut, toCompleteWith: failure(.invalidData), when: {
            client.complete(withStatusCode: 200, data: invalidJsonData)
        })
    }

    func test_load_deliversNoItemsOn200HttpResponseWithEmptyJSONList() {
        let jsonWithEmptyListData: Data = makeJSONData(items: [])
        let url: URL = anyURL()
        let (sut, client) = makeSut(url: url)

        expect(sut: sut, toCompleteWith: .success([]), when: {
            client.complete(withStatusCode: 200, data: jsonWithEmptyListData)
        })
    }

    func test_load_deliversItemsOn200HttpResponseWithJSONList() {
        let item1 = makeItem(
            id: .init(),
            description: "Description 1",
            location: "Location 1",
            imageURL: anyURL()
        )

        let item2 = makeItem(
            id: .init(),
            description: "Description 2",
            location: "Location 2",
            imageURL: anyURL()
        )

        let jsonWithListData: Data = makeJSONData(items: [item1.json, item2.json])
        let url: URL = anyURL()
        let (sut, client) = makeSut(url: url)

        expect(sut: sut, toCompleteWith: .success([item1.model, item2.model]), when: {
            client.complete(withStatusCode: 200, data: jsonWithListData)
        })
    }

    func test_load_shouldNotDeliverResultAfterBeingDeallocated() {
        let client: HttpClientSpy = .init()
        var sut: RemoteFeedLoader? = .init(url: anyURL(), client: client)

        var capturedResults: [Result<[FeedItem], Error>] = []
        sut?.fetchItems { capturedResults.append($0) }
        sut = nil
        client.complete(withStatusCode: 200, data: makeJSONData(items: []))

        XCTAssertTrue(capturedResults.isEmpty, "Result should not have been delivered.")
    }

    // MARK: Helpers:
    class HttpClientSpy: HTTPClient {
        var messages: [(url: URL, completion: (Result<(Data, HTTPURLResponse), Error>) -> Void)] = []
        var requestedURLs: [URL] { messages.map(\.url) }

        func load(from url: URL, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void) {
            messages.append((url, completion))
        }

        func complete(with error: Error, atIndex index: Int = 0) {
            messages[index].completion(.failure(error))
        }

        func complete(withStatusCode statusCode: Int, data: Data, atIndex index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!

            messages[index].completion(.success((data, response)))
        }
    }

    func expect(
        sut: RemoteFeedLoader,
        toCompleteWith expectedResult: FeedLoader.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for fetchItems completion")
        sut.fetchItems { result in
            switch (result, expectedResult) {
            case let (.success(items), .success(expectedItems)):
                XCTAssertEqual(items, expectedItems, file: file, line: line)

            case let (.failure(error as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(error, expectedError, file: file, line: line)

            default:
                XCTFail("Expected result \(expectedResult), got \(result)", file: file, line: line)
            }

            expectation.fulfill()
        }

        action()

        wait(for: [expectation], timeout: 1.0)
    }

    func makeSut(url: URL) -> (sut: RemoteFeedLoader, client: HttpClientSpy) {
        let client: HttpClientSpy = .init()
        let sut: RemoteFeedLoader = .init(url: url, client: client)
        trackForMemoryLeaks(client)
        trackForMemoryLeaks(sut)

        return (sut, client)
    }

    func failure(_ error: RemoteFeedLoader.Error) -> FeedLoader.Result {
        return .failure(error)
    }

    func makeItem(id: UUID, description: String?, location: String?, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let item: FeedItem = .init(id: id, description: description, location: location, imageURL: imageURL)
        let json: [String: Any] = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues { $0 }

        return (item, json)
    }

    func makeJSONData(items: [[String: Any]]) -> Data {
        let json: [String: Any] = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    func anyURL() -> URL {
        return URL(string: "http://any.url")!
    }

    func invalidJsonData() -> Data {
        return .init("Invalid JSON".utf8)
    }
}
