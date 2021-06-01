//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class LoadFeedFromCacheUseCase: XCTestCase {
    func test_init_shouldNotDeleteCache() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_load_requestsCacheRetrival() {
        let (sut, store) = makeSUT()

        sut.loadFeed { _ in }

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_deliversErrorOnRetrievalError() {
        let expectedError: NSError = anyNSError()
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .failure(expectedError), when: {
            store.completeRetrieval(with: expectedError)
        })
    }

    func test_load_deliversNoFeedOnEmptyCache() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrivalWithEmptyCache()
        })
    }

    func test_load_deliversCachedImagesOnLessThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate: Date = .init()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let lessThanSevenDaysOldTimestamp: Date = fixedCurrentDate.adding(days: -7).adding(seconds: 1)

        expect(sut, toCompleteWith: .success(feed.models), when: {
            store.completeRetrievalSuccessfully(with: feed.locals, timestamp: lessThanSevenDaysOldTimestamp)
        })
    }

    func test_load_deliversNoFeedImagesOnSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate: Date = .init()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let sevenDaysOldTimestamp: Date = fixedCurrentDate.adding(days: -7)

        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrievalSuccessfully(with: feed.locals, timestamp: sevenDaysOldTimestamp)
        })
    }

    func test_load_deliversNoFeedImagesOnMoreThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate: Date = .init()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let moreThanSevenDaysOldTimestamp: Date = fixedCurrentDate.adding(days: -7).adding(seconds: -1)

        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrievalSuccessfully(with: feed.locals, timestamp: moreThanSevenDaysOldTimestamp)
        })
    }

    func test_load_hasNoSideEffectOnRetrievalError() {
        let (sut, store) = makeSUT()

        sut.loadFeed { _ in }
        store.completeRetrieval(with: anyNSError())

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_hasNoSideEffectOnEmptyCache() {
        let (sut, store) = makeSUT()

        sut.loadFeed { _ in }
        store.completeRetrivalWithEmptyCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_hasNoSideEffectOnLessThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate: Date = .init()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let lessThanSevenDaysOldTimestamp: Date = fixedCurrentDate.adding(days: -7).adding(seconds: 1)

        sut.loadFeed { _ in }
        store.completeRetrievalSuccessfully(with: feed.locals, timestamp: lessThanSevenDaysOldTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_deletesSevenDaysOldCacheUponRetrieval() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate: Date = .init()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let sevenDaysOldTimestamp: Date = fixedCurrentDate.adding(days: -7)

        sut.loadFeed { _ in }
        store.completeRetrievalSuccessfully(with: feed.locals, timestamp: sevenDaysOldTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }

    func test_load_deletesMoreThanSevenDaysOldCacheUponRetrieval() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate: Date = .init()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let moreThanSevenDaysOldTimestamp: Date = fixedCurrentDate.adding(days: -7).adding(seconds: -1)

        sut.loadFeed { _ in }
        store.completeRetrievalSuccessfully(with: feed.locals, timestamp: moreThanSevenDaysOldTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }

    func test_load_doesNotDeliverResultUponDeallocation() {
        let store: FeedStoreSpy = .init()
        var sut: LocalFeedLoader? = .init(store: store, currentDate: Date.init)

        sut?.loadFeed { _ in }
        sut = nil
        store.completeRetrivalWithEmptyCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    // MARK: - Helper
    private func makeSUT(
        currentDate: @escaping () -> Date = { .init() },
        file: StaticString = #file,
        line: UInt = #line
    ) -> (LocalFeedLoader, FeedStoreSpy) {
        let store: FeedStoreSpy = FeedStoreSpy()
        let sut: LocalFeedLoader = .init(store: store, currentDate: currentDate)

        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }

    private func expect(
        _ sut: LocalFeedLoader,
        toCompleteWith expectedResult: LocalFeedLoader.LoadResult,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp: XCTestExpectation = .init(description: "Wait for load result.")
        var receivedResult: LocalFeedLoader.LoadResult?

        sut.loadFeed { result in
            receivedResult = result
            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1.0)

        switch (receivedResult, expectedResult) {
        case let (.success(receivedFeed), .success(expectedFeed)):
            XCTAssertEqual(
                receivedFeed,
                expectedFeed,
                "Expected \(expectedFeed), but recived \(receivedFeed) instead.",
                file: file,
                line: line
            )

        case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
            XCTAssertEqual(
                receivedError,
                expectedError,
                "Expected \(expectedError), but recived \(receivedError) instead.",
                file: file,
                line: line
            )

        default:
            XCTFail(
                "Expected \(expectedResult), but received \(String(describing: receivedResult)) instead",
                file: file,
                line: line
            )
        }
    }

    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }

    private func anyNSError() -> NSError {
        return .init(domain: "any domain", code: 42, userInfo: nil)
    }

    private func uniqueImage() -> FeedImage {
        return .init(id: UUID(), description: "any", location: "any", url: anyURL())
    }

    private func uniqueImageFeed() -> (models: [FeedImage], locals: [LocalFeedImage]) {
        let feed: [FeedImage] = [uniqueImage(), uniqueImage()]
        let locals: [LocalFeedImage] = feed.map { image in
            LocalFeedImage(id: image.id, description: image.description, location: image.location, url: image.url)
        }

        return (feed, locals)
    }
}

private extension Date {
    func adding(seconds: Int) -> Self {
        let calendar: Calendar = .init(identifier: .gregorian)
        return calendar.date(byAdding: .second, value: seconds, to: self)!
    }

    func adding(days: Int) -> Self {
        let calendar: Calendar = .init(identifier: .gregorian)
        return calendar.date(byAdding: .day, value: days, to: self)!
    }
}


