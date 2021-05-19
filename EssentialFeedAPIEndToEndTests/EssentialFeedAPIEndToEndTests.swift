//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

class EssentialFeedAPIEndToEndTests: XCTestCase {
    func test_endToEndTestServerGETFeedResult_matchesFixedTestAccountData() {
        let testServerURL: URL = URL(string: "http://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client: URLSessionHTTPClient = .init()
        let loader: RemoteFeedLoader = .init(url: testServerURL, client: client)

        let expectation: XCTestExpectation = .init(description: "Wait for response.")
        var capturedResult: FeedLoader.Result?

        loader.fetchItems { result in
            capturedResult = result
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        switch capturedResult {
        case let .success(items)?:
            XCTAssertEqual(items[0], expectedImage(at: 0))
            XCTAssertEqual(items[1], expectedImage(at: 1))
            XCTAssertEqual(items[2], expectedImage(at: 2))
            XCTAssertEqual(items[3], expectedImage(at: 3))
            XCTAssertEqual(items[4], expectedImage(at: 4))
            XCTAssertEqual(items[5], expectedImage(at: 5))
            XCTAssertEqual(items[6], expectedImage(at: 6))
            XCTAssertEqual(items[7], expectedImage(at: 7))

        case let .failure(error)?:
            XCTFail("Expected fetch items call to succeed, but received error instead: \(error).")

        default:
            XCTFail("Expected to receive successful response.")
        }
    }

    // MARK: - Helpers
    private func expectedImage(at index: Int) -> FeedItem {
        return FeedItem(
            id: id(at: index),
            description: description(at: index),
            location: location(at: index),
            imageURL: imageURL(at: index))
    }

    private func id(at index: Int) -> UUID {
        return UUID(uuidString: [
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "BA298A85-6275-48D3-8315-9C8F7C1CD109",
            "5A0D45B3-8E26-4385-8C5D-213E160A5E3C",
            "FF0ECFE2-2879-403F-8DBE-A83B4010B340",
            "DC97EF5E-2CC9-4905-A8AD-3C351C311001",
            "557D87F1-25D3-4D77-82E9-364B2ED9CB30",
            "A83284EF-C2DF-415D-AB73-2A9B8B04950B",
            "F79BD7F8-063F-46E2-8147-A67635C3BB01"
        ][index])!
    }

    private func description(at index: Int) -> String? {
        return [
            "Description 1",
            nil,
            "Description 3",
            nil,
            "Description 5",
            "Description 6",
            "Description 7",
            "Description 8"
        ][index]
    }

    private func location(at index: Int) -> String? {
        return [
            "Location 1",
            "Location 2",
            nil,
            nil,
            "Location 5",
            "Location 6",
            "Location 7",
            "Location 8"
        ][index]
    }

    private func imageURL(at index: Int) -> URL {
        return URL(string: "https://url-\(index+1).com")!
    }
}
