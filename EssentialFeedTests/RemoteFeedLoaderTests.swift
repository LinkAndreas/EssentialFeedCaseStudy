//  Copyright © 2021 Andreas Link. All rights reserved.

import XCTest

class RemoteFeedLoader {}
class HttpClient {
    var requestedURL: URL?
}

class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let client = HttpClient()
        let _ = RemoteFeedLoader()

        XCTAssertNil(client.requestedURL)
    }
}
