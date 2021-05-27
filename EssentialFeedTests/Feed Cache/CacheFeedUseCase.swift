//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

public protocol FeedStore {
    typealias DeletionCompletion = (Result<Void, Error>) -> Void
    typealias InsertionCompletion = (Result<Void, Error>) -> Void

    func insert(items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
}

public class LocalFeedLoader {
    typealias SaveCompletion = (Result<Void, Error>) -> Void

    private let store: FeedStore
    private let currentDate: () -> Date

    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    func save(items: [FeedItem], completion: @escaping SaveCompletion) {
        store.deleteCachedFeed { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.store.insert(items: items, timestamp: self.currentDate()) { [weak self] result in
                    guard self != nil else { return }

                    completion(result)
                }

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

class CacheFeedUseCase: XCTestCase {
    func test_init_doesNotMessageStoreOnCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()

        sut.save(items: [uniqueItem(), uniqueItem()]) { _ in }

        XCTAssertEqual(store.deletionCompletions.count, 1)
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let items: [FeedItem] = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        let deletionError: Error = anyNSError()

        sut.save(items: items) { _ in }
        store.completeDeletion(with: deletionError, atIndex: 0)

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }

    func test_save_requestsNewCacheInsertionWithTimestampOnCacheDeletion() {
        let timestamp: Date = .init()
        let items: [FeedItem] = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT(currentDate: { timestamp })

        sut.save(items: items) { _ in }
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(items: items, timestamp: timestamp)])
    }

    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError: NSError = anyNSError()

        expect(sut, toCompleteWith: .failure(deletionError), when: {
            store.completeDeletion(with: deletionError)
        })
    }

    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let insertionError: NSError = anyNSError()

        expect(sut, toCompleteWith: .failure(insertionError), when: {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        })
    }

    func test_save_suceedsOnSuccessfulInsertion() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success(()), when: {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        })
    }

    func test_save_doesNotDeliverResultAfterDeletionErrorOnDeallocation() {
        let items: [FeedItem] = [uniqueItem(), uniqueItem()]
        let store: FeedStoreSpy = .init()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store) { .init() }
        let deletionError: NSError = anyNSError()

        var receivedResult: Result<Void, Error>?
        sut?.save(items: items) { result in
            receivedResult = result
        }

        sut = nil
        store.completeDeletion(with: deletionError)

        XCTAssertNil(receivedResult, "Result should not have been delivered")
    }

    func test_save_doesNotDeliverResultAfterInsertionErrorOnDeallocation() {
        let items: [FeedItem] = [uniqueItem(), uniqueItem()]
        let store: FeedStoreSpy = .init()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store) { .init() }
        let insertionError: NSError = anyNSError()

        var receivedResult: Result<Void, Error>?
        sut?.save(items: items) { result in
            receivedResult = result
        }

        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: insertionError)

        XCTAssertNil(receivedResult, "Result should not have been delivered")
    }

    // MARK: - Helpers
    private func expect(
        _ sut: LocalFeedLoader,
        toCompleteWith expectedResult: Result<Void, Error>,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let items: [FeedItem] = [uniqueItem(), uniqueItem()]
        let exp: XCTestExpectation = .init(description: "expectation")
        var receivedResult: Result<Void, Error>?

        sut.save(items: items) { result in
            switch result {
            case .success:
                receivedResult = .success(())

            case let .failure(error as NSError):
                receivedResult = .failure(error)
            }

            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1.0)

        switch (receivedResult, expectedResult) {
        case (.success, .success):
            return

        case let (.failure(error1 as NSError), .failure(error2 as NSError)):
            XCTAssertEqual(error1, error2)

        default:
            XCTFail("Expected \(String(describing: receivedResult)) to equl \(expectedResult)", file: file, line: line)
        }
    }

    private func makeSUT(
        currentDate: @escaping () -> Date = { .init() },
        file: StaticString = #file,
        line: UInt = #line
    ) -> (LocalFeedLoader, FeedStoreSpy) {
        let store: FeedStoreSpy = .init()
        let sut: LocalFeedLoader = .init(store: store, currentDate: currentDate)

        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (sut, store)
    }

    private func uniqueItem() -> FeedItem {
        return .init(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }

    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }

    private func anyNSError() -> NSError {
        return .init(domain: "any domain", code: 42, userInfo: nil)
    }

    private class FeedStoreSpy: FeedStore {
        enum Message: Equatable {
            case deleteCachedFeed
            case insert(items: [FeedItem], timestamp: Date)
        }

        var receivedMessages: [Message] = []
        var deletionCompletions: [DeletionCompletion] = []
        var insertionCompletions: [InsertionCompletion] = []

        func insert(items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
            insertionCompletions.append(completion)
            receivedMessages.append(.insert(items: items, timestamp: timestamp))
        }

        func deleteCachedFeed(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            receivedMessages.append(.deleteCachedFeed)
        }

        func completeDeletion(with error: Error, atIndex index: Int = 0) {
            deletionCompletions[index](.failure(error))
        }

        func completeDeletionSuccessfully(atIndex index: Int = 0) {
            deletionCompletions[index](.success(()))
        }

        func completeInsertion(with error: Error, atIndex index: Int = 0) {
            insertionCompletions[index](.failure(error))
        }

        func completeInsertionSuccessfully(atIndex index: Int = 0) {
            insertionCompletions[index](.success(()))
        }
    }
}


