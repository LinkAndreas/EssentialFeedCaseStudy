//  Copyright © 2021 Andreas Link. All rights reserved.

import XCTest
import EssentialFeed

class CoreDataFeedImageDataStoreTests: XCTestCase {
    func test_retrieveImageData_deliversNotFoundWhenEmpty() {
        let sut = makeSUT()

        expect(sut, toCompleteWith: notFound(), for: anyURL())
    }

    func test_retrieveImageData_deliversNotFoundWhenStoredDataURLDoesNotMatch() {
        let url = URL(string: "http://a-url.com")!
        let notMatchingURL = URL(string: "http://another-url.com")!

        let sut = makeSUT()

        insert(anyData(), into: sut, for: url)

        expect(sut, toCompleteWith: notFound(), for: notMatchingURL)
    }

    func test_retrieveImageData_deliversFoundDataWhenThereIsAStoredImageDataMatchingURL() {
        let url = anyURL()
        let sut = makeSUT()
        let storedData = anyData()

        insert(storedData, into: sut, for: url)

        expect(sut, toCompleteWith: found(storedData), for: url)
    }

    func test_retrieveImageData_deliversLastInsertedValue() {
        let url = anyURL()
        let sut = makeSUT()
        let firstInsertedData = Data("first".utf8)
        let lastInsertedData = Data("last".utf8)

        insert(firstInsertedData, into: sut, for: url)
        insert(lastInsertedData, into: sut, for: url)

        expect(sut, toCompleteWith: found(lastInsertedData), for: url)
    }
}

extension CoreDataFeedImageDataStoreTests {
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CoreDataFeedStore {
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try! CoreDataFeedStore(storeURL: storeURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func localImage(for url: URL) -> LocalFeedImage {
        return .init(id: UUID(), description: "any", location: "any", url: url)
    }

    private func notFound() -> Result<Data?, Error> {
        return .success(.none)
    }

    private func found(_ data: Data) -> Result<Data?, Error> {
        return .success(data)
    }

    private func expect(
        _ sut: FeedImageDataStore,
        toCompleteWith expectedResult: Result<Data?, Error>,
        for url: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let receivedResult = Result { try sut.retrieve(dataForURL: url) }
        switch (expectedResult, receivedResult) {
        case (let .success(expectedData), let .success(recievedData)):
            XCTAssertEqual(
                expectedData,
                recievedData,
                "Expected to receive \(String(describing: expectedData)), but received \(String(describing: recievedData)) instead.",
                file: file,
                line: line
            )

        case (let .failure(expectedError as NSError), let .failure(receivedError as NSError)):
            XCTAssertEqual(
                expectedError,
                receivedError,
                "Expected to receive \(expectedError), but received \(receivedError) instead.",
                file: file,
                line: line
            )

        default:
            XCTFail(
                "Expected to receive \(expectedResult), but received \(receivedResult) instead.",
                file: file,
                line: line
            )
        }
    }

    private func insert(
        _ data: Data,
        into sut: CoreDataFeedStore,
        for url: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for result.")
        let image = localImage(for: url)
        sut.insert(feed: [image], timestamp: Date()) { result in
            switch result {
            case .success:
                let result = Result { try sut.insert(data, for: url) }
                if case let .failure(receivedError) = result {
                    XCTFail(
                        "Expected data store insertion to succeed, but recieved error instead: \(receivedError)",
                        file: file,
                        line: line
                    )
                }

                expectation.fulfill()

            case let .failure(receivedError):
                XCTFail(
                    "Expected data store insertion to succeed, but recieved error instead: \(receivedError)",
                    file: file,
                    line: line
                )

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
