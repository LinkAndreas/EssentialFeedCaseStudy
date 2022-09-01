//  Copyright © 2021 Andreas Link. All rights reserved.

import XCTest
import EssentialFeed

final class LoadFeedImageDataFromCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (spy, _) = makeSUT()

        XCTAssertTrue(spy.receivedMessages.isEmpty)
    }

    func test_loadImageData_requestsStoreDataForURL() throws {
        let url = anyURL()
        let (spy, sut) = makeSUT()

        spy.stubRetrievalResult(with: .success(anyData()))
        _ = try sut.loadImageData(from: url)

        XCTAssertEqual(spy.receivedMessages, [.retrieve(dataFor: url)])
    }

    func test_loadImageData_deliversErrorOnStoreError() {
        let error = anyNSError()
        let (spy, sut) = makeSUT()

        expect(sut, toCompleteWith: failed(), when: {
            spy.stubRetrievalResult(with: .failure(error))
        })
    }

    func test_loadImageData_deliversNotFoundErrorOnNotFound() {
        let (spy, sut) = makeSUT()

        expect(sut, toCompleteWith: notFound(), when: {
            spy.stubRetrievalResult(with: .success(.none))
        })
    }

    func test_loadImageData_deliversStoredDataOnFoundData() {
        let (spy, sut) = makeSUT()
        let foundData = anyData()

        expect(sut, toCompleteWith: .success(foundData), when: {
            spy.stubRetrievalResult(with: .success(foundData))
        })
    }

    // MARK: - Helper
    private func failed() -> Result<Data, Error> {
        return .failure(LocalFeedImageDataLoader.LoadError.failed)
    }

    private func notFound() -> Result<Data, Error> {
        return .failure(LocalFeedImageDataLoader.LoadError.notFound)
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
        toCompleteWith expectedResult: Result<Data, Error>,
        when action: () -> Void
    ) {
        let url = anyURL()

        action()

        let receivedResult = Result {
            try sut.loadImageData(from: url)
        }

        switch (receivedResult, expectedResult) {
        case let (.success(receivedData), .success(expectedData)):
            XCTAssertEqual(
                receivedData,
                expectedData,
                "Expected to receive \(String(describing: receivedData)), but received \(String(describing: receivedData)) instead."
            )

        case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
            XCTAssertEqual(
                receivedError,
                expectedError,
                "Expected to receive \(expectedError), but received \(receivedError) instead."
            )

        default:
            XCTFail("Expected to receive \(expectedResult), but received \(String(describing: receivedResult)) instead.")
        }
    }
}
