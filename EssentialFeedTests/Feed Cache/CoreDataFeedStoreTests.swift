//  Copyright © 2021 Andreas Link. All rights reserved.

import CoreData
import EssentialFeed
import XCTest

final class CoreDataFeedStore: FeedStore {
    public func insert(feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {

    }

    public func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.empty)
    }
}

final class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs {
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()

        assertThatRetriveDeliversEmptyOnOmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectOnEmptyCache() {

    }

    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {

    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {

    }

    func test_insert_deliversNoErrorOnNonEmptyCache() {

    }

    func test_insert_deliversNoErrorOnEmptyCache() {

    }

    func test_insert_overridesPreviouslyCachedData() {

    }

    func test_delete_deliversNoErrorOnEmptyCache() {
        
    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {
        
    }

    func test_delete_emptiesPreviouslyInsertedCache() {
        
    }

    func test_delete_deliversNoErrorOnNonEmptyCache() {
        
    }

    func test_storeSideEffects_runSerially() {
        
    }

    // MARK: - Helpers:

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let bundle: Bundle = .init(for: CoreDataFeedStoreTests.self)
        let storeURL: URL = .init(fileURLWithPath: "/dev/null")

        let sut = CoreDataFeedStore()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
