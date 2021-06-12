//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class CodableFeedStoreCacheTests: XCTestCase, FailableFeedStoreSpecs {
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

    func test_insert_deliversFailureOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed()
        let timestamp = Date()

        let receivedError = insert(feed.locals, timestamp , into: sut)

        XCTAssertNotNil(receivedError, "Expected to receive error, but received success instead.")
    }

    func test_insert_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()

        insert(uniqueImageFeed().locals, Date() , into: sut)

        let receivedError = insert(uniqueImageFeed().locals, Date() , into: sut)

        XCTAssertNil(receivedError, "Expected insert to succeed, but received error \(String(describing: receivedError)) instead.")
    }

    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed()
        let timestamp = Date()

        let receivedError = insert(feed.locals, timestamp , into: sut)

        XCTAssertNil(receivedError, "Expected insert to succeed, but received error \(String(describing: receivedError)) instead.")
    }

    func test_insert_hasNoSideEffectsOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed()
        let timestamp = Date()

        insert(feed.locals, timestamp , into: sut)

        expect(sut, toCompleteWith: .empty)
    }

    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()

        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected deletion to succeed, but received error instead: \(String(describing: deletionError)).")
    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let noDeletePermissonURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissonURL)

        deleteCache(from: sut)

        expect(sut, toCompleteWith: .empty)
    }

    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed()
        let timestamp = Date()

        insert(feed.locals, timestamp, into: sut)
        deleteCache(from: sut)

        expect(sut, toCompleteWith: .empty)
    }

    func test_delete_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed()
        let timestamp = Date()

        insert(feed.locals, timestamp, into: sut)
        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected deletion to succeed, but received error instead: \(String(describing: deletionError)).")
    }

    func test_delete_deliversFailureOnDeletionError() {
        let noDeletePermissonURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissonURL)

        let deletionError = deleteCache(from: sut)

        XCTAssertNotNil(deletionError, "Expected to fail, but received successful result instead.")
    }

    func test_delete_hasNoSideEffectsOnDeletionError() {
        let noDeletePermissonURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissonURL)

        deleteCache(from: sut)

        expect(sut, toCompleteWith: .empty)
    }

    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()

        let op1 = expectation(description: "Operation 1")
        sut.insert(feed: uniqueImageFeed().locals, timestamp: Date()) { _ in
            op1.fulfill()
        }

        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            op2.fulfill()
        }

        let op3 = expectation(description: "Operation 3")
        sut.insert(feed: uniqueImageFeed().locals, timestamp: Date()) { _ in
            op3.fulfill()
        }

        wait(for: [op1, op2, op3], timeout: 5.0, enforceOrder: true)
    }

    // MARK: - Helpers
    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let sut: CodableFeedStore = .init(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }

    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
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
