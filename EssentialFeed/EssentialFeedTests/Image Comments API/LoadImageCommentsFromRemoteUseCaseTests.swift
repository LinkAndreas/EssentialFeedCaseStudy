//  Copyright © 2022 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class LoadImageCommentsFromRemoteUseCaseTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let url = anyURL()
        let (_, client) = makeSut(url: url)

        XCTAssertEqual(client.requestedURLs, [])
    }

    func test_load_requestsDataFromURL() {
        let url: URL = anyURL()
        let (sut, client) = makeSut(url: url)

        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURLTwice() {
        let url: URL = anyURL()
        let (sut, client) = makeSut(url: url)

        sut.load { _ in }
        sut.load { _ in }

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

    func test_load_deliversErrorOnNon2xxHttpResponse() {
        let validJsonData: Data = makeJSONData(items: [])
        let url: URL = anyURL()
        let (sut, client) = makeSut(url: url)

        let samples: [Int] = [199, 150, 300, 400, 500]
        samples.enumerated().forEach { index, statusCode in
            expect(sut: sut, toCompleteWith: failure(.invalidData), when: {
                client.complete(withStatusCode: statusCode, data: validJsonData, atIndex: index)
            })
        }
    }

    func test_load_deliversErrorOn2xxHttpResponseWithInvalidJson() {
        let invalidJsonData: Data = invalidJsonData()
        let url: URL = anyURL()
        let (sut, client) = makeSut(url: url)

        let samples: [Int] = [200, 201, 250, 280, 299]
        samples.enumerated().forEach { index, statusCode in
            expect(sut: sut, toCompleteWith: failure(.invalidData), when: {
                client.complete(withStatusCode: statusCode, data: invalidJsonData, atIndex: index)
            })
        }
    }

    func test_load_deliversNoItemsOn2xxHttpResponseWithEmptyJSONList() {
        let jsonWithEmptyListData: Data = makeJSONData(items: [])
        let url: URL = anyURL()
        let (sut, client) = makeSut(url: url)

        let samples: [Int] = [200, 201, 250, 280, 299]
        samples.enumerated().forEach { index, statusCode in
            expect(sut: sut, toCompleteWith: .success([]), when: {
                client.complete(withStatusCode: statusCode, data: jsonWithEmptyListData, atIndex: index)
            })
        }
    }

    func test_load_deliversItemsOn2xxHttpResponseWithJSONList() {
        let comment1 = makeComment(
            id: UUID(),
            message: "message",
            createdAt: (Date(timeIntervalSince1970: 1598627222), "2020-08-28T15:07:02+00:00"),
            username: "a username"
        )

        let comment2 = makeComment(
            id: UUID(),
            message: "another message",
            createdAt: (Date(timeIntervalSince1970: 1577881882), "2020-01-01T12:31:22+00:00"),
            username: "another username"
        )

        let jsonWithListData: Data = makeJSONData(items: [comment1.json, comment2.json])
        let url: URL = anyURL()
        let (sut, client) = makeSut(url: url)

        let samples: [Int] = [200, 201, 250, 280, 299]
        samples.enumerated().forEach { index, statusCode in
            expect(sut: sut, toCompleteWith: .success([comment1.model, comment2.model]), when: {
                client.complete(withStatusCode: statusCode, data: jsonWithListData, atIndex: index)
            })
        }
    }

    func test_load_shouldNotDeliverResultAfterBeingDeallocated() {
        let client: HttpClientSpy = .init()
        var sut: RemoteImageCommentsLoader? = .init(url: anyURL(), client: client)

        var capturedResults: [Result<[ImageComment], Error>] = []
        sut?.load { capturedResults.append($0) }
        sut = nil
        client.complete(withStatusCode: 200, data: makeJSONData(items: []))

        XCTAssertTrue(capturedResults.isEmpty, "Result should not have been delivered.")
    }

    // MARK: Helpers:
    func expect(
        sut: RemoteImageCommentsLoader,
        toCompleteWith expectedResult: RemoteImageCommentsLoader.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for fetchItems completion")
        sut.load { result in
            switch (result, expectedResult) {
            case let (.success(items), .success(expectedItems)):
                XCTAssertEqual(items, expectedItems, file: file, line: line)

            case let (.failure(error as RemoteImageCommentsLoader.Error), .failure(expectedError as RemoteImageCommentsLoader.Error)):
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
    ) -> (sut: RemoteImageCommentsLoader, client: HttpClientSpy) {
        let client: HttpClientSpy = .init()
        let sut: RemoteImageCommentsLoader = .init(url: url, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (sut, client)
    }

    func failure(_ error: RemoteImageCommentsLoader.Error) -> RemoteImageCommentsLoader.Result {
        return .failure(error)
    }

    func makeComment(id: UUID, message: String, createdAt: (Date, String), username: String) -> (model: ImageComment, json: [String: Any]) {
        let item: ImageComment = .init(id: id, message: message, createdAt: createdAt.0, username: username)
        let json: [String: Any] = [
            "id": id.uuidString,
            "message": message,
            "created_at": createdAt.1,
            "author": [
                "username": username
            ]
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
