//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class FeedImageDataMapperTests: XCTestCase {
    func test_map_throwsInvalidDataErrorOnNon200HTTPResponse() throws {
        XCTAssertThrowsError(
            try FeedImageDataMapper.map(data: anyData(), response: HTTPURLResponse(statusCode: 243))
        )
    }

    func test_map_throwsInvalidDataErrorOnEmpty200HTTPResponse() throws {
        let emptyData = Data()

        XCTAssertThrowsError(
            try FeedImageDataMapper.map(data: emptyData, response: HTTPURLResponse(statusCode: 200))
        )
    }

    func test_map_deliversReceivedDataOnNonEmpty200HTTPResponse() throws {
        let nonEmptyData = "Non empty data".data(using: .utf8)!
        let result = try FeedImageDataMapper.map(data: nonEmptyData, response: HTTPURLResponse(statusCode: 200))

        XCTAssertEqual(result, nonEmptyData)
    }
}
