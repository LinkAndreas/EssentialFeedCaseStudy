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

    private let storeURL: URL

    init(storeURL: URL) {
        self.storeURL = storeURL
    }

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

        setupEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()

        undoStoreSideEffects()
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()

        expect(sut, toCompleteWith: .empty)
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

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)

        expect(sut, toCompleteWith: .found(feed: feed.locals, timestamp: timestamp))
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
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

            sut.retrieve { firstResult in
                sut.retrieve { secondResult in
                    switch (firstResult, secondResult) {
                    case let (
                        .found(firstReceivedFeed, firstReceivedTimestamp),
                        .found(secondReceivedFeed, secondReceivedTimestamp)
                    ):
                        XCTAssertEqual(
                            firstReceivedFeed,
                            feed.locals,
                            "Expected \(feed.locals), but received \(firstReceivedFeed) instead."
                        )
                        XCTAssertEqual(
                            secondReceivedFeed,
                            feed.locals,
                            "Expected \(feed.locals), but received \(secondReceivedFeed) instead."
                        )
                        XCTAssertEqual(
                            firstReceivedTimestamp,
                            timestamp,
                            "Expected \(timestamp), but received \(firstReceivedTimestamp) instead."
                        )
                        XCTAssertEqual(
                            secondReceivedTimestamp,
                            timestamp,
                            "Expected \(timestamp), but received \(secondReceivedTimestamp) instead."
                        )

                    default:
                        XCTFail(
                            "Expected receive twice from non empty cache delivers same result with feed: \(feed) and timestamp: \(timestamp), but received \(firstResult) and \(secondResult) instead."
                        )
                    }

                    exp.fulfill()
                }
            }
        }

        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Helpers
    private func makeSUT() -> CodableFeedStore {
        let sut: CodableFeedStore = .init(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(sut)
        return sut
    }

    private func expect(
        _ sut: CodableFeedStore,
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

            case (.empty, .empty):
                break

            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError)

            default:
                XCTFail("Expected result: \(expectedResult), but received \(receivedResult) instead.")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("\(type(of: self)).store")
    }

    private func setupEmptyStoreState() {
       deleteStoreArtefacts()
    }

    private func undoStoreSideEffects() {
        deleteStoreArtefacts()
    }

    private func deleteStoreArtefacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}
