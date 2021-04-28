//  Copyright © 2021 Andreas Link. All rights reserved.

import XCTest

class RemoteFeedLoader {
    let url: URL
    let client: HttpClient

    init(url: URL, client: HttpClient) {
        self.url = url
        self.client = client
    }

    func fetchItems() {
        client.requestedURL = url
    }
}

class HttpClient {
    var requestedURL: URL?
}

class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let url: URL = anyURL()
        let client: HttpClient = .init()
        let _ = RemoteFeedLoader(url: url, client: client)

        XCTAssertNil(client.requestedURL)
    }

    func test_load_requestsDataFromURL() {
        let url: URL = anyURL()
        let client: HttpClient = .init()
        let sut: RemoteFeedLoader = .init(url: url, client: client)

        sut.fetchItems()

        XCTAssertEqual(client.requestedURL, url)
    }

    // MARK: Helpers:
    func anyURL() -> URL {
        return URL(string: "http://any.url")!
    }
}
