//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

class CodableFeedStore: FeedStore {
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

    func retrieve(completion: @escaping RetrievalCompletion) {
        guard let data: Data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }

        let decoder: JSONDecoder = .init()
        do {
            let decoded = try decoder.decode(Cache.self, from: data)
            completion(.found(feed: decoded.feed.map(\.local), timestamp: decoded.timestamp))
        } catch {
            completion(.failure(error: error))
        }
    }

    func insert(feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let encoder: JSONEncoder = .init()
        do {
            let encoded = try encoder.encode(Cache(feed: feed.map(CodableFeedImage.init(from:)), timestamp: timestamp))
            try encoded.write(to: storeURL)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        guard FileManager.default.fileExists(atPath: storeURL.path) else { return completion(.success(())) }

        do {
            try FileManager.default.removeItem(at: storeURL)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
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

        expect(sut, toCompleteTwiceWith: .empty)
    }

    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()

        let feed = uniqueImageFeed()
        let timestamp = Date()

        insert(feed.locals, timestamp, into: sut)
        expect(sut, toCompleteWith: .found(feed: feed.locals, timestamp: timestamp))
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()

        let feed = uniqueImageFeed()
        let timestamp = Date()

        insert(feed.locals, timestamp, into: sut)
        expect(sut, toCompleteTwiceWith: .found(feed: feed.locals, timestamp: timestamp))
    }

    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL: URL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "Invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        expect(sut, toCompleteWith: .failure(error: anyNSError()))
    }

    func test_retrieve_hasNoSideEffectsOnFailure() {
        let storeURL: URL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "Invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        expect(sut, toCompleteTwiceWith: .failure(error: anyNSError()))
    }

    func test_insert_overridesPreviouslyCachedData() {
        let sut = makeSUT()

        let firstFeed = uniqueImageFeed()
        let firstTimestamp = Date()

        let secondFeed = uniqueImageFeed()
        let secondTimestamp = Date()

        insert(firstFeed.locals, firstTimestamp , into: sut)
        insert(secondFeed.locals, secondTimestamp, into: sut)
        expect(sut, toCompleteWith: .found(feed: secondFeed.locals, timestamp: secondTimestamp))
    }

    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)

        let feed = uniqueImageFeed()
        let timestamp = Date()

        let receivedError = insert(feed.locals, timestamp , into: sut)
        XCTAssertNotNil(receivedError, "Expected to receive error, but received success instead.")
    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected deletion to succeed, but received error instead: \(String(describing: deletionError)).")
        expect(sut, toCompleteWith: .empty)
    }

    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed()
        let timestamp = Date()

        insert(feed.locals, timestamp, into: sut)
        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected deletion to succeed, but received error instead: \(String(describing: deletionError)).")
        expect(sut, toCompleteWith: .empty)
    }

    func test_delete_deliversFailureOnDeletionError() {
        let noDeletePermissonURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissonURL)

        let deletionError = deleteCache(from: sut)
        XCTAssertNotNil(deletionError, "Expected to fail, but received successful result instead.")
        expect(sut, toCompleteWith: .empty)
    }

    // MARK: - Helpers
    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let sut: CodableFeedStore = .init(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func expect(
        _ sut: CodableFeedStore,
        toCompleteTwiceWith expectedResult: RetrieveCachedFeedResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toCompleteWith: expectedResult, file: file, line: line)
        expect(sut, toCompleteWith: expectedResult, file: file, line: line)
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
    private func insert(_ feed: [LocalFeedImage], _ timestamp: Date, into sut: CodableFeedStore) -> Error? {
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
    private func deleteCache(from sut: CodableFeedStore) -> Error? {
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

        wait(for: [exp], timeout: 1.0)

        return receivedError
    }

    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("\(type(of: self)).store")
    }

    private func cachesDirectory() -> URL {
        return testSpecificStoreURL().deletingLastPathComponent()
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
