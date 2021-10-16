//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class RemoteImageDataLoader {
    let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }
}

final class LoadFeedImageDataFromRemoteUseCaseTests: XCTestCase {
    func test_init_doesNotRequestAnyURL() {
        let (spy, _) = makeSUT()

        XCTAssertEqual(spy.requestedURLs, [], "Requested URLs must be empty.")
    }

    // MARK: - Helper
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (HttpClientSpy, RemoteImageDataLoader) {
        let client = HttpClientSpy()
        let sut = RemoteImageDataLoader(client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (client, sut)
    }
}
