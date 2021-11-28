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
        let sut = makeFeedLoader()

        expect(sut, toCompleteLoadWith: .success([]))
    }

    func test_load_deliversItemsSavedOnASeparateInstance() {
        let sutToPerformSave = makeFeedLoader()
        let sutToPerformLoad = makeFeedLoader()
        let imageFeed = uniqueImageFeed().models

        save(imageFeed, with: sutToPerformSave)

        expect(sutToPerformLoad, toCompleteLoadWith: .success(imageFeed))
    }

    func test_save_overridesItemsSavedOnASeparateInstance() {
        let sutToPerformFirstSave = makeFeedLoader()
        let sutToPerformLastSave = makeFeedLoader()
        let sutToPerformLoad = makeFeedLoader()
        let firstFeed = uniqueImageFeed().models
        let latestFeed = uniqueImageFeed().models

        save(firstFeed, with: sutToPerformFirstSave)
        save(latestFeed, with: sutToPerformLastSave)

        expect(sutToPerformLoad, toCompleteLoadWith: .success(latestFeed))
    }

    func test_loadImageData_deliversSavedDataOnASeparateInstance() {
        let sutToPerformSave = makeImageLoader()
        let sutToPerformLoad = makeImageLoader()
        let feedLoader = makeFeedLoader()
        let image = uniqueImage()
        let imageData = anyData()

        save([image], with: feedLoader)
        save(imageData, in: sutToPerformSave, for: image.url)

        expect(sutToPerformLoad, toCompleteLoadWith: .success(imageData), for: image.url)
    }

    // MARK: - Helpers
    private func makeFeedLoader(file: StaticString = #filePath, line: UInt = #line) -> LocalFeedLoader {
        let storeURL = testSpecificStoreURL()
        let store = try! CoreDataFeedStore(storeURL: storeURL)
        let sut = LocalFeedLoader(store: store, currentDate: Date.init)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func makeImageLoader(file: StaticString = #filePath, line: UInt = #line) -> LocalFeedImageDataLoader {
        let storeURL = testSpecificStoreURL()
        let store = try! CoreDataFeedStore(storeURL: storeURL)
        let sut = LocalFeedImageDataLoader(store: store)
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

    private func expect(
        _ sut: LocalFeedLoader,
        toCompleteLoadWith expectedResult: LocalFeedLoader.LoadResult,
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

    private func expect(
        _ sut: LocalFeedImageDataLoader,
        toCompleteLoadWith expectedResult: LocalFeedImageDataLoader.LoadResult,
        for url: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for result")
        _ = sut.loadImageData(from: url) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(
                    receivedData,
                    expectedData, "Expected to receive \(String(describing: expectedData)), but received \(String(describing: receivedData)) instead.",
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
                    "Expected to recieve \(expectedResult), but received: \(receivedResult) instead.",
                    file: file,
                    line: line
                )
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    private func save(
        _ imageFeed: [FeedImage],
        with sut: LocalFeedLoader,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for result")
        sut.save(feed: imageFeed) { result in
            switch result {
            case .success:
                break

            case let .failure(receivedError):
                XCTFail(
                    "Expected to succeed, but received \(receivedError) instead.",
                    file: file,
                    line: line
                )
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    private func save(
        _ imageData: Data,
        in sut: LocalFeedImageDataLoader,
        for url: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for result")
        sut.save(imageData, for: url) { result in
            switch result {
            case .success:
                break

            case let .failure(receivedError):
                XCTFail(
                    "Expected to succeed, but received \(receivedError) instead.",
                    file: file,
                    line: line
                )
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
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
