//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date

    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    func save(items: [FeedItem], completion: @escaping (Result<Void, Error>) -> Void) {
        store.deleteCachedFeed { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.store.insert(items: items, timestamp: self.currentDate())

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

class FeedStore {
    enum Message: Equatable {
        case deleteCachedFeed
        case insert(items: [FeedItem], timestamp: Date)
    }

    var deletionCompletions: [(Result<Void, Error>) -> Void] = []
    var receivedMessages: [Message] = []

    func insert(items: [FeedItem], timestamp: Date) {
        receivedMessages.append(.insert(items: items, timestamp: timestamp))
    }

    func deleteCachedFeed(completion: @escaping (Result<Void, Error>) -> Void) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }

    func completeDeletion(with error: Error, atIndex index: Int = 0) {
        deletionCompletions[index](.failure(error))
    }

    func completeDeletionSuccessfully(atIndex index: Int = 0) {
        deletionCompletions[index](.success(()))
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
        let items: [FeedItem] = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        let deletionError: NSError = anyNSError()

        let exp: XCTestExpectation = .init(description: "expectation")
        var receivedError: Error?

        sut.save(items: items) { result in
            switch result {
            case .success: break

            case let .failure(error):
                receivedError = error
                exp.fulfill()
            }
        }

        store.completeDeletion(with: deletionError)

        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedError as NSError?, deletionError)
    }

    // MARK: - Helpers
    private func makeSUT(
        currentDate: @escaping () -> Date = { .init() },
        file: StaticString = #file, line: UInt = #line
    ) -> (LocalFeedLoader, FeedStore) {
        let store: FeedStore = .init()
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
}


