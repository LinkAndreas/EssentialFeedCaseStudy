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
}

extension CoreDataFeedImageDataStoreTests {
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CoreDataFeedStore {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func localImage(for url: URL) -> LocalFeedImage {
        return .init(id: UUID(), description: "any", location: "any", url: url)
    }

    private func notFound() -> FeedImageDataStore.RetrievalResult {
        return .success(.none)
    }

    private func expect(
        _ sut: FeedImageDataStore,
        toCompleteWith expectedResult: FeedImageDataStore.RetrievalResult,
        for url: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for result.")
        sut.retrieve(dataForURL: url) { receivedResult in
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

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
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
                sut.insert(data, for: url) { result in
                    guard case let .failure(receivedError) = result else { return }

                    XCTFail(
                        "Expected data store insertion to succeed, but recieved error instead: \(receivedError)",
                        file: file,
                        line: line
                    )
                }

            case let .failure(receivedError):
                XCTFail(
                    "Expected data store insertion to succeed, but recieved error instead: \(receivedError)",
                    file: file,
                    line: line
                )
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
