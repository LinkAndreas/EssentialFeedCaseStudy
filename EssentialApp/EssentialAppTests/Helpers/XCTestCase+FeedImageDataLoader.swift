//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

protocol FeedImageDataLoaderTestCase: XCTestCase {}

extension FeedImageDataLoaderTestCase {
    func expect(
        _ sut: FeedImageDataLoader,
        toCompleteWith expectedResult: Result<Data, Error>,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let url = anyURL()

        action()

        let receivedResult = Result {
            try sut.loadImageData(from: url)
        }

        switch (receivedResult, expectedResult) {
        case let (.success(receivedFeed), .success(expectedFeed)):
            XCTAssertEqual(
                receivedFeed,
                expectedFeed,
                "Expected to receive \(expectedFeed), but received \(receivedFeed) instead.",
                file: file,
                line: line
            )

        case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
            XCTAssertEqual(
                receivedError,
                expectedError,
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
}

