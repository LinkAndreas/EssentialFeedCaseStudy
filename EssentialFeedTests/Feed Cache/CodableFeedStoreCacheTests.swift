//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

class CodableFeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
    }

    private struct CodableFeedImage: Equatable, Codable {
        let id: UUID
        let description: String?
        let location: String?
        let url: URL

        init(id: UUID, description: String?, location: String?, url: URL) {
            self.id = id
            self.description = description
            self.location = location
            self.url = url
        }

        init(from feedImage: LocalFeedImage) {
            id = feedImage.id
            description = feedImage.description
            location = feedImage.location
            url = feedImage.url
        }

        var local: LocalFeedImage {
            return .init(id: id, description: description, location: location, url: url)
        }
    }

    private let storeURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .first!.appendingPathComponent("image-feed.store")

    func insert(feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder: JSONEncoder = .init()
        let encoded = try! encoder.encode(Cache(feed: feed.map(CodableFeedImage.init(from:)), timestamp: timestamp))
        try! encoded.write(to: storeURL)
        completion(.success(()))
    }

    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data: Data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }

        let decoder: JSONDecoder = .init()
        let decoded = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: decoded.feed.map(\.local), timestamp: decoded.timestamp))
    }
}

final class CodableFeedStoreCacheTests: XCTestCase {
    override func setUp() {
        super.setUp()

        let storeURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    override func tearDown() {
        super.tearDown()

        let storeURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()

        let exp: XCTestExpectation = .init(description: "Wait for result.")
        sut.retrieve { result in
            switch result {
            case .empty:
                break

            default:
                XCTFail("Expected empty result, but received \(result) instead.")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_retrieve_hasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()

        let exp: XCTestExpectation = .init(description: "Wait for result.")
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break

                default:
                    XCTFail("Expected (empty, empty) results, but received \(firstResult) and \(secondResult) instead.")
                }

                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValue() {
        let sut = makeSUT()

        let feed = uniqueImageFeed()
        let timestamp = Date()
        let exp: XCTestExpectation = .init(description: "Wait for result.")
        sut.insert(feed: feed.locals, timestamp: timestamp) { result in
            switch result {
            case .success:
                break

            case let .failure(error):
                XCTFail("Expected insert to succeed, receiver error instead: \(error)")
            }

            sut.retrieve { result in
                switch result {
                case let .found(receivedFeed, receivedTimestamp):
                    XCTAssertEqual(
                        receivedFeed,
                        feed.locals,
                        "Expected \(feed), but received \(receivedFeed) instead."
                    )
                    XCTAssertEqual(
                        receivedTimestamp,
                        timestamp,
                        "Expected \(timestamp), but received \(receivedTimestamp) instead."
                    )

                default:
                    XCTFail("Expected found result with \(feed) and timestamp \(timestamp), but received \(result) instead.")
                }

                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1.0)
    }


    // MARK: - Helpers
    private func makeSUT() -> CodableFeedStore {
        let sut: CodableFeedStore = .init()
        trackForMemoryLeaks(sut)
        return sut
    }
}
