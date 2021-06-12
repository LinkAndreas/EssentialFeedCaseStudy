//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

extension FeedStoreSpecs where Self: XCTestCase {
    func expect(
        _ sut: FeedStore,
        toCompleteTwiceWith expectedResult: RetrieveCachedFeedResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toCompleteWith: expectedResult, file: file, line: line)
        expect(sut, toCompleteWith: expectedResult, file: file, line: line)
    }

    func expect(
        _ sut: FeedStore,
        toCompleteWith expectedResult: RetrieveCachedFeedResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp: XCTestExpectation = .init(description: "Wait for result.")
        sut.retrieve { receivedResult in
            switch (receivedResult, expectedResult) {

            case let (.found(receivedFeed, receivedTimestamp), .found(expectedFeed, expectedTimestamp)):
                XCTAssertEqual(
                    receivedFeed,
                    expectedFeed,
                    "Expected to receive feed: \(expectedFeed), but received \(receivedFeed) instead.",
                    file: file,
                    line: line
                )
                XCTAssertEqual(
                    receivedTimestamp,
                    expectedTimestamp,
                    "Expected to receive timestamp: \(expectedTimestamp), but received \(receivedTimestamp) instead.",
                    file: file,
                    line: line
                )

            case (.empty, .empty), (.failure, .failure):
                break

            default:
                XCTFail(
                    "Expected result: \(expectedResult), but received \(receivedResult) instead.",
                    file: file,
                    line: line
                )
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    @discardableResult
    func insert(_ feed: [LocalFeedImage], _ timestamp: Date, into sut: FeedStore) -> Error? {
        let exp: XCTestExpectation = .init(description: "Wait for cache insertion.")
        var receivedError: Error?
        sut.insert(feed: feed, timestamp: timestamp) { result in
            switch result {
            case .success:
                break

            case let .failure(error):
                receivedError = error
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)

        return receivedError
    }

    @discardableResult
    func deleteCache(from sut: FeedStore) -> Error? {
        let exp: XCTestExpectation = .init(description: "Wait for cache deletion.")
        var receivedError: Error?
        sut.deleteCachedFeed { result in
            switch result {
            case .success:
                break

            case let .failure(error):
                receivedError = error
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 5.0)

        return receivedError
    }
}
