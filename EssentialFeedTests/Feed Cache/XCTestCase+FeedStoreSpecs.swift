//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

extension FeedStoreSpecs where Self: XCTestCase {
    func assertThatRetriveDeliversEmptyOnOmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toCompleteWith: .success(.empty), file: file, line: line)
    }

    func assertThatRetrieveHasNoSideEffectOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toCompleteTwiceWith: .success(.empty), file: file, line: line)
    }

    func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let feed = uniqueImageFeed()
        let timestamp = Date()

        insert(feed.locals, timestamp, into: sut)

        expect(
            sut,
            toCompleteWith: .success(.found(feed: feed.locals, timestamp: timestamp)),
            file: file,
            line: line
        )
    }

    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let feed = uniqueImageFeed()
        let timestamp = Date()

        insert(feed.locals, timestamp, into: sut)

        expect(
            sut,
            toCompleteTwiceWith: .success(.found(feed: feed.locals, timestamp: timestamp)),
            file: file,
            line: line
        )
    }

    func assertThatInsertOverridesPreviouslyCachedData(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let firstFeed = uniqueImageFeed()
        let firstTimestamp = Date()
        let secondFeed = uniqueImageFeed()
        let secondTimestamp = Date()

        insert(firstFeed.locals, firstTimestamp , into: sut)
        insert(secondFeed.locals, secondTimestamp, into: sut)

        expect(
            sut,
            toCompleteWith: .success(.found(feed: secondFeed.locals, timestamp: secondTimestamp)),
            file: file,
            line: line
        )
    }

    func assertThatInsertDeliversNoErrorOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        insert(uniqueImageFeed().locals, Date() , into: sut)

        let receivedError = insert(uniqueImageFeed().locals, Date(), into: sut)

        XCTAssertNil(receivedError, "Expected insert to succeed, but received error \(String(describing: receivedError)) instead.", file: file, line: line)
    }

    func assertThatInsertDeliversNoErrorOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let receivedError = insert(uniqueImageFeed().locals, Date(), into: sut)

        XCTAssertNil(receivedError, "Expected insert to succeed, but received error \(String(describing: receivedError)) instead.", file: file, line: line)
    }

    func assertThatDeleteDeliversNoErrorOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected deletion to succeed, but received error instead: \(String(describing: deletionError)).", file: file, line: line)
    }

    func assertThatDeleteHasNoSideEffectsOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        deleteCache(from: sut)

        expect(sut, toCompleteWith: .success(.empty), file: file, line: line)
    }

    func assertThatDeleteEmptiesPreviouslyInsertedCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        insert(uniqueImageFeed().locals, Date(), into: sut)
        deleteCache(from: sut)

        expect(sut, toCompleteWith: .success(.empty), file: file, line: line)
    }

    func assertThatDeleteDeliversNoErrorOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        insert(uniqueImageFeed().locals, Date(), into: sut)
        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected deletion to succeed, but received error instead: \(String(describing: deletionError)).", file: file, line: line)
    }

    func assertThatStoreSideEffectsRunSerially(on sut: FeedStore) {
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
}

extension FailableRetrieveFeedStoreSpecs where Self: XCTestCase {
    func assertThatRetrieveDeliversFailureOnRetrievalError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toCompleteWith: .failure(anyNSError()), file: file, line: line)
    }

    func assertThatRetrieveHasNoSideEffectsOnRetrievalError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toCompleteTwiceWith: .failure(anyNSError()), file: file, line: line)
    }
}

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
    func assertThatInsertDeliversFailureOnInsertionError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let receivedError = insert(uniqueImageFeed().locals, Date(), into: sut)

        XCTAssertNotNil(
            receivedError,
            "Expected to receive error, but received success instead.",
            file: file,
            line: line
        )
    }

    func assertThatInsertHasNoSideEffectsOnInsertionError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        insert(uniqueImageFeed().locals, Date(), into: sut)

        expect(sut, toCompleteWith: .success(.empty), file: file, line: line)
    }
}


extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
    func assertThatDeleteDeliversFailureOnDeletionError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let deletionError = deleteCache(from: sut)

        XCTAssertNotNil(deletionError, "Expected to fail, but received successful result instead.", file: file, line: line)
    }

    func assertThatDeleteHasNoSideEffectsOnDeletionError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        deleteCache(from: sut)

        expect(sut, toCompleteWith: .success(.empty), file: file, line: line)
    }
}

extension FeedStoreSpecs where Self: XCTestCase {
    // MARK: - Helper
    func expect(
        _ sut: FeedStore,
        toCompleteTwiceWith expectedResult: FeedStore.RetrievalResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toCompleteWith: expectedResult, file: file, line: line)
        expect(sut, toCompleteWith: expectedResult, file: file, line: line)
    }

    func expect(
        _ sut: FeedStore,
        toCompleteWith expectedResult: FeedStore.RetrievalResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp: XCTestExpectation = .init(description: "Wait for result.")
        sut.retrieve { receivedResult in
            switch (receivedResult, expectedResult) {

            case
                let (
                    .success(.found(receivedFeed, receivedTimestamp)),
                    .success(.found(expectedFeed, expectedTimestamp))
                ):
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

            case (.success(.empty), .success(.empty)), (.failure, .failure):
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
    func insert(_ feed: [LocalFeedImage], _ timestamp: Date, into sut: FeedStore) -> Error? {
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
    func deleteCache(from sut: FeedStore) -> Error? {
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

        wait(for: [exp], timeout: 5.0)

        return receivedError
    }
}
