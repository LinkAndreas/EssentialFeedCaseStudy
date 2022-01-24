//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

class LoadFeedFromRemoteUseCaseTests: XCTestCase {
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

    // MARK: Helpers:
    func expect(
        sut: RemoteFeedLoader,
        toCompleteWith expectedResult: FeedLoader.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for fetchItems completion")
        sut.load { result in
            switch (result, expectedResult) {
            case let (.success(items), .success(expectedItems)):
                XCTAssertEqual(items, expectedItems, file: file, line: line)

            case let (.failure(error as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(error, expectedError, file: file, line: line)

            default:
                XCTFail("Expected result \(expectedResult), got \(result)", file: file, line: line)
            }

            expectation.fulfill()
        }

        action()

        wait(for: [expectation], timeout: 1.0)
    }

    func makeSut(
        url: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteFeedLoader, client: HttpClientSpy) {
        let client: HttpClientSpy = .init()
        let sut: RemoteFeedLoader = .init(url: url, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (sut, client)
    }

    func failure(_ error: RemoteFeedLoader.Error) -> FeedLoader.Result {
        return .failure(error)
    }

    func makeItem(id: UUID, description: String?, location: String?, imageURL: URL) -> (model: FeedImage, json: [String: Any]) {
        let item: FeedImage = .init(id: id, description: description, location: location, url: imageURL)
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

    func invalidJsonData() -> Data {
        return .init("Invalid JSON".utf8)
    }
}
