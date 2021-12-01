//  Copyright © 2021 Andreas Link. All rights reserved.

import XCTest
import EssentialFeed

final class CacheFeedImageDataUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (spy, _) = makeSUT()

        XCTAssertTrue(spy.receivedMessages.isEmpty)
    }

    func test_saveImageDataForURL_requestsImageDataInsertionForURLIntoStore() {
        let imageData = anyData()
        let url = anyURL()
        let (spy, sut) = makeSUT()

        sut.save(imageData, for: url) { _ in }

        XCTAssertEqual(spy.receivedMessages, [.insert(imageData: imageData, url: url)])
    }

    func test_saveImageDataFromURL_failsOnStoreInsertionError() {
        let error = anyNSError()
        let (spy, sut) = makeSUT()

        expect(sut, toCompleteWith: failed(), when: {
            spy.completeDataInsertion(with: .failure(error))
        })
    }

    func test_saveImageDataFromURL_succeedsOnSuccessfulStoreInsertion() {
        let (spy, sut) = makeSUT()

        expect(sut, toCompleteWith: success(), when: {
            spy.completeDataInsertion(with: .success(()))
        })
    }

    func test_saveImageDataFromURL_doesNotDeliverResultAfterInstanceHasBeenDeallocated() {
        let imageData = anyData()
        let url = anyURL()
        let store: FeedImageDataStoreSpy = FeedImageDataStoreSpy()
        var sut: LocalFeedImageDataLoader? = LocalFeedImageDataLoader(store: store)

        var receivedResults: [LocalFeedImageDataLoader.SaveResult] = []
        sut?.save(imageData, for: url) { result in
            receivedResults.append(result)
        }

        sut = nil
        store.completeDataInsertion(with: success())

        XCTAssertTrue(
            receivedResults.isEmpty,
            "Result should not be delivered after instance has been deallocated"
        )
    }

    // MARK: - Helper
    private func failed() -> LocalFeedImageDataLoader.SaveResult {
        return .failure(LocalFeedImageDataLoader.SaveError.failed)
    }

    private func success() -> LocalFeedImageDataLoader.SaveResult {
        return .success(())
    }

    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (FeedImageDataStoreSpy, LocalFeedImageDataLoader) {
        let store = FeedImageDataStoreSpy()
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (store, sut)
    }

    private func expect(
        _ sut: LocalFeedImageDataLoader,
        toCompleteWith expectedResult: LocalFeedImageDataLoader.SaveResult,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let imageData = anyData()
        let url = anyURL()

        let expectation = expectation(description: "Wait for result")
        var receivedResult: LocalFeedImageDataLoader.SaveResult?

        sut.save(imageData, for: url) { result in
            receivedResult = result
            expectation.fulfill()
        }

        action()

        wait(for: [expectation], timeout: 1.0)

        switch (expectedResult, receivedResult) {
        case (.success, .success):
            break

        case let (.failure(expectedError as LocalFeedImageDataLoader.SaveError), .failure(receivedError as LocalFeedImageDataLoader.SaveError)):
            XCTAssertEqual(
                expectedError,
                receivedError,
                "Expected to receive \(expectedError), but received \(receivedError)",
                file: file,
                line: line
            )

        default:
            XCTFail(
                "Expected to receive \(expectedResult), but received \(String(describing: receivedResult)) instead",
                file: file,
                line: line
            )
        }
    }
}
