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

    // MARK: - Helper
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
}
