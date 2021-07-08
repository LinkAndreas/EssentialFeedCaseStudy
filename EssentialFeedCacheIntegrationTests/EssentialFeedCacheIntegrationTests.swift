//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

class EssentialFeedCacheIntegrationTests: XCTestCase {
    override func setUp() {
        super.setUp()

        setupEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()

        undoStoreSideEffects()
    }

    func test_load_deliversNoItemsOnEmptyCache() {
        let sut = makeSUT()

        expect(sut, toCompleteLoadWith: .success([]))
    }

    func test_load_deliversItemsSavedOnASeparateInstance() {
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let imageFeed = uniqueImageFeed().models

        save(imageFeed, with: sutToPerformSave)

        expect(sutToPerformLoad, toCompleteLoadWith: .success(imageFeed))
    }

    func test_save_overridesItemsSavedOnASeparateInstance() {
        let sutToPerformFirstSave = makeSUT()
        let sutToPerformLastSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let firstFeed = uniqueImageFeed().models
        let latestFeed = uniqueImageFeed().models

        save(firstFeed, with: sutToPerformFirstSave)
        save(latestFeed, with: sutToPerformLastSave)

        expect(sutToPerformLoad, toCompleteLoadWith: .success(latestFeed))
    }

    // MARK: - Helpers
    private func expect(
        _ sut: LocalFeedLoader,
        toCompleteLoadWith expectedResult: Result<[FeedImage], Error>,
        file: StaticString = #filePath,
        line: UInt8 = #line
    ) {
        let exp = expectation(description: "Wait for result")
        sut.fetchFeed { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedFeed), .success(expectedFeed)):
                XCTAssertEqual(
                    receivedFeed,
                    expectedFeed, "Expected to receive \(expectedFeed), but received \(receivedFeed) instead."
                )

            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(
                    receivedError,
                    expectedError,
                    "Expected to receive \(expectedError), but received \(receivedError) instead."
                )

            default:
                XCTFail("Expected to recieve \(expectedResult), but received: \(receivedResult) instead.")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    private func save(
        _ imageFeed: [FeedImage],
        with sut: LocalFeedLoader,
        file: StaticString = #filePath,
        line: UInt8 = #line
    ) {
        let exp = expectation(description: "Wait for result")
        sut.save(feed: imageFeed) { result in
            switch result {
            case .success:
                break

            case let .failure(receivedError):
                XCTFail("Expected to succeed, but received \(receivedError) instead.")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> LocalFeedLoader {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = testSpecificStoreURL()
        let store = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
        let sut = LocalFeedLoader(store: store, currentDate: Date.init)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func testSpecificStoreURL() -> URL {
        cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }

    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }

    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }

    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}
