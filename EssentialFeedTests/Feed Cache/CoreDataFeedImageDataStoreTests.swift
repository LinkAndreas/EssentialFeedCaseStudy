//  Copyright © 2021 Andreas Link. All rights reserved.

import XCTest
import EssentialFeed

final class CoreDataFeedImageDataStore: FeedImageDataStore {
    init(storeURL: URL, bundle: Bundle) throws {

    }

    func retrieve(dataForURL url: URL, completion: @escaping (RetrievalResult) -> Void) {
        completion(.success(.none))
    }

    func insert(_ imageData: Data, for url: URL, completion: @escaping (InsertionResult) -> Void) {

    }
}

class CoreDataFeedImageDataStoreTests: XCTestCase {
    func test_retrieveImageData_deliversNotFoundWhenEmpty() {
        let sut = makeSUT()

        expect(sut, toCompleteWith: notFound(), for: anyURL())
    }
}

extension CoreDataFeedImageDataStoreTests {
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> FeedImageDataStore {
        let storeBundle = Bundle(for: CoreDataFeedImageDataStore.self)
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try! CoreDataFeedImageDataStore(storeURL: storeURL, bundle: storeBundle)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
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
}
