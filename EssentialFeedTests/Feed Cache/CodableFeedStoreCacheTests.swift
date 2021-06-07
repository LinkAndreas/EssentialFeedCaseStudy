//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

class CodableFeedStore {
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        completion(.empty)
    }
}

final class CodableFeedStoreCacheTests: XCTestCase {
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()

        let exp: XCTestExpectation = .init(description: "Wait for result.")
        sut.retrieve { result in
            switch result {
            case .empty:
                break

            default:
                XCTFail("Expected empty result, but received \(result) instead.")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Helpers
    private func makeSUT() -> CodableFeedStore {
        let sut: CodableFeedStore = .init()
        return sut
    }
}
