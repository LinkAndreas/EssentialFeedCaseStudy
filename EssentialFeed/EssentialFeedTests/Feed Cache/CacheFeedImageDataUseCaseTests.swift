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

        try? sut.save(imageData, for: url)

        XCTAssertEqual(spy.receivedMessages, [.insert(imageData: imageData, url: url)])
    }

    func test_saveImageDataFromURL_failsOnStoreInsertionError() {
        let error = anyNSError()
        let (spy, sut) = makeSUT()

        expect(sut, toCompleteWith: failed(), when: {
            spy.stubInsertionResult(with: .failure(error))
        })
    }

    func test_saveImageDataFromURL_succeedsOnSuccessfulStoreInsertion() {
        let (spy, sut) = makeSUT()

        expect(sut, toCompleteWith: success(), when: {
            spy.stubInsertionResult(with: .success(()))
        })
    }

    // MARK: - Helper
    private func failed() -> Result<Void, Error> {
        return .failure(LocalFeedImageDataLoader.SaveError.failed)
    }

    private func success() -> Result<Void, Error> {
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
        toCompleteWith expectedResult: Result<Void, Error>,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let imageData = anyData()
        let url = anyURL()

        action()

        let receivedResult = Result {
            try sut.save(imageData, for: url)
        }

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
