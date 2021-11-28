//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

class EssentialFeedAPIEndToEndTests: XCTestCase {
    func test_endToEndTestServerLoadFeedResult_matchesFixedTestAccountData() {
        switch loadFeedResult() {
        case let .success(feed)?:
            XCTAssertEqual(feed[0], expectedImage(at: 0))
            XCTAssertEqual(feed[1], expectedImage(at: 1))
            XCTAssertEqual(feed[2], expectedImage(at: 2))
            XCTAssertEqual(feed[3], expectedImage(at: 3))
            XCTAssertEqual(feed[4], expectedImage(at: 4))
            XCTAssertEqual(feed[5], expectedImage(at: 5))
            XCTAssertEqual(feed[6], expectedImage(at: 6))
            XCTAssertEqual(feed[7], expectedImage(at: 7))

        case let .failure(error)?:
            XCTFail("Expected fetch feed to succeed, but received error instead: \(error).")

        default:
            XCTFail("Expected to receive successful response.")
        }
    }

    func test_endToEndTestServerLoadImageData_deliversImageData() {
        switch loadImageData() {
        case let .success(.some(imageData)):
            XCTAssertFalse(imageData.isEmpty, "Expected non empty image data.")

        case .failure(RemoteImageDataLoader.Error.connectivity):
            XCTFail("Excpected fetch image data to succeed, but received connectivity error instead.")

        case .failure(RemoteImageDataLoader.Error.invalidData):
            XCTFail("Excpected fetch image data to succeed, but received invalid data error instead.")

        default:
            XCTFail("Expected to receive successful response.")
        }
    }

    // MARK: - Helpers
    private func loadImageData(file: StaticString = #file, line: UInt = #line) -> RemoteImageDataLoader.Result? {
        let testServerURL: URL = feedTestServerURL.appendingPathComponent("73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6/image")
        let loader = RemoteImageDataLoader(client: ephemeralClient())

        trackForMemoryLeaks(loader, file: file, line: line)

        let expectation = expectation(description: "Wait for response.")
        var receivedResult: RemoteImageDataLoader.Result?
        _ = loader.loadImageData(from: testServerURL) { result in
            receivedResult = result
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        return receivedResult
    }

    private func loadFeedResult(file: StaticString = #file, line: UInt = #line) -> FeedLoader.Result? {
        let loader: RemoteFeedLoader = .init(url: feedTestServerURL, client: ephemeralClient())

        trackForMemoryLeaks(loader, file: file, line: line)

        let expectation: XCTestExpectation = .init(description: "Wait for response.")
        var capturedResult: FeedLoader.Result?

        loader.fetchFeed { result in
            capturedResult = result
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        return capturedResult
    }

    private func expectedImage(at index: Int) -> FeedImage {
        return FeedImage(
            id: id(at: index),
            description: description(at: index),
            location: location(at: index),
            url: imageURL(at: index))
    }

    private func ephemeralClient(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration)
        let client: URLSessionHTTPClient = .init(session: session)
        trackForMemoryLeaks(client, file: file, line: line)
        return client
    }

    private var feedTestServerURL: URL {
        return URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
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
