//  Copyright © 2021 Andreas Link. All rights reserved.

import XCTest
import EssentialFeed

final class LocalFeedImageDataLoaderTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (spy, _) = makeSUT()

        XCTAssertTrue(spy.receivedMessages.isEmpty)
    }

    func test_loadImageData_requestsStoreDataForURL() {
        let url = anyURL()
        let (spy, sut) = makeSUT()

        _ = sut.loadImageData(from: url) { _ in }

        XCTAssertEqual(spy.receivedMessages, [.retrieve(dataFor: url)])
    }

    func test_loadImageData_deliversErrorOnStoreError() {
        let error = anyNSError()
        let (spy, sut) = makeSUT()

        expect(sut, toCompleteWith: failed(), when: {
            spy.completeDataRetrieval(with: .failure(error))
        })
    }

    func test_loadImageData_deliversNotFoundErrorOnNotFound() {
        let (spy, sut) = makeSUT()

        expect(sut, toCompleteWith: notFound(), when: {
            spy.completeDataRetrieval(with: .success(.none))
        })
    }

    func test_loadImageData_deliversStoredDataOnFoundData() {
        let (spy, sut) = makeSUT()
        let foundData = anyData()

        expect(sut, toCompleteWith: .success(foundData), when: {
            spy.completeDataRetrieval(with: .success(foundData))
        })
    }

    func test_loadImageData_doesNotDeliverResultAfterCancellingTask() {
        let url = anyURL()
        let (spy, sut) = makeSUT()

        var receivedResults: [LocalFeedImageDataLoader.Result] = []
        let task = sut.loadImageData(from: url) { result in
            receivedResults.append(result)
        }

        task.cancel()

        spy.completeDataRetrieval(with: .success(.none))
        spy.completeDataRetrieval(with: .success(anyData()))
        spy.completeDataRetrieval(with: .failure(anyNSError()))

        XCTAssertTrue(receivedResults.isEmpty, "Should not receive result after cancelling task.")
    }

    func test_loadImageData_doesNotDeliverResultAfterSUTInstanceGotDeallocated() {
        let url = anyURL()
        let spy = StoreSpy()
        var sut: LocalFeedImageDataLoader? = LocalFeedImageDataLoader(store: spy)

        var receivedResults: [LocalFeedImageDataLoader.Result] = []
        _ = sut?.loadImageData(from: url) { result in
            receivedResults.append(result)
        }

        sut = nil

        spy.completeDataRetrieval(with: .success(.none))
        spy.completeDataRetrieval(with: .success(anyData()))
        spy.completeDataRetrieval(with: .failure(anyNSError()))

        XCTAssertTrue(receivedResults.isEmpty, "Should not receive result after cancelling task.")
    }

    func test_saveImageDataForURL_requestsImageDataInsertionForURLIntoStore() {
        let imageData = anyData()
        let url = anyURL()
        let (spy, sut) = makeSUT()

        sut.save(imageData, for: url) { _ in }

        XCTAssertEqual(spy.receivedMessages, [.insert(imageData: imageData, url: url)])
    }

    // MARK: - Helper
    private func failed() -> LocalFeedImageDataLoader.Result {
        return .failure(LocalFeedImageDataLoader.Error.failed)
    }

    private func notFound() -> LocalFeedImageDataLoader.Result {
        return .failure(LocalFeedImageDataLoader.Error.notFound)
    }

    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (StoreSpy, LocalFeedImageDataLoader) {
        let store = StoreSpy()
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (store, sut)
    }

    private func expect(
        _ sut: LocalFeedImageDataLoader,
        toCompleteWith expectedResult: FeedImageDataLoader.Result,
        when action: () -> Void
    ) {
        let url = anyURL()

        let expectation = expectation(description: "Wait for load result.")
        var receivedResult: FeedImageDataLoader.Result?

        _ = sut.loadImageData(from: url) { result in
            receivedResult = result
            expectation.fulfill()
        }

        action()

        wait(for: [expectation], timeout: 1.0)

        switch (receivedResult, expectedResult) {
        case let (.success(receivedData)?, .success(expectedData)):
            XCTAssertEqual(
                receivedData,
                expectedData,
                "Expected to receive \(String(describing: receivedData)), but received \(String(describing: receivedData)) instead."
            )

        case let (.failure(receivedError as NSError)?, .failure(expectedError as NSError)):
            XCTAssertEqual(
                receivedError,
                expectedError,
                "Expected to receive \(expectedError), but received \(receivedError) instead."
            )

        default:
            XCTFail("Expected to receive \(expectedResult), but received \(String(describing: receivedResult)) instead.")
        }
    }

    private class StoreSpy: FeedImageDataStore {
        enum Message: Equatable {
            case retrieve(dataFor: URL)
            case insert(imageData: Data, url: URL)
        }

        private (set) var receivedMessages: [Message] = []
        private var completions: [(FeedImageDataStore.Result) -> Void] = []
        private var insertionCompletions: [(FeedImageDataStore.InsertionResult) -> Void] = []

        func retrieve(dataForURL url: URL, completion: @escaping (FeedImageDataStore.Result) -> Void) {
            receivedMessages.append(.retrieve(dataFor: url))
            completions.append(completion)
        }

        func insert(_ imageData: Data, for url: URL, completion: @escaping (FeedImageDataStore.InsertionResult) -> Void) {
            receivedMessages.append(.insert(imageData: imageData, url: url))
            insertionCompletions.append(completion)
        }

        func completeDataRetrieval(with result: FeedImageDataStore.Result, atIndex index: Int = 0) {
            completions[index](result)
        }

        func completeDataInsertion(with result: FeedImageDataStore.InsertionResult, atIndex index: Int = 0) {
            insertionCompletions[index](result)
        }
    }
}
