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

    func save(items: [FeedItem]) {
        store.deleteCachedFeed { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.store.insert(items: items, timestamp: self.currentDate())

            case .failure:
                break
            }
        }
    }
}

class FeedStore {
    var deletionCompletions: [(Result<Void, Error>) -> Void] = []
    var insertions: [(items: [FeedItem], timestamp: Date)] = []
    var insertionCallCount: Int { insertions.count }

    var deleteCacheCallCount: Int { deletionCompletions.count }

    func insert(items: [FeedItem], timestamp: Date) {
        insertions.append((items, timestamp))
    }

    func deleteCachedFeed(completion: @escaping (Result<Void, Error>) -> Void) {
        deletionCompletions.append(completion)
    }

    func completeDeletion(with error: Error, atIndex index: Int = 0) {
        deletionCompletions[index](.failure(error))
    }

    func completeDeletionSuccessfully(atIndex index: Int = 0) {
        deletionCompletions[index](.success(()))
    }
}

class CacheFeedUseCase: XCTestCase {
    func test_init_doesNotDeleteFeedOnCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.deleteCacheCallCount, 0)
    }

    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()

        sut.save(items: [uniqueItem(), uniqueItem()])

        XCTAssertEqual(store.deleteCacheCallCount, 1)
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let items: [FeedItem] = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        let deletionError: Error = anyError()

        sut.save(items: items)
        store.completeDeletion(with: deletionError, atIndex: 0)

        XCTAssertEqual(store.insertionCallCount, 0)
    }

    func test_save_requestsNewCacheInsertionWithTimestampOnCacheDeletion() {
        let timestamp: Date = .init()
        let items: [FeedItem] = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT(currentDate: { timestamp })

        sut.save(items: items)
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.insertions.count, 1)
        XCTAssertEqual(store.insertions.first?.items, items)
        XCTAssertEqual(store.insertions.first?.timestamp, timestamp)
    }

    // MARK: - Helpers
    private func makeSUT(currentDate: @escaping () -> Date = { .init() }, file: StaticString = #file, line: UInt = #line) -> (LocalFeedLoader, FeedStore) {
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

    private func anyError() -> Error {
        return NSError(domain: "any domain", code: 42, userInfo: nil)
    }
}


