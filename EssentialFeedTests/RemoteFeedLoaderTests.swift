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
        client.load(from: url)
    }
}

protocol HttpClient {
    func load(from url: URL)
}

class HttpClientSpy: HttpClient {
    var requestedURL: URL?

    func load(from url: URL) {
        requestedURL = url
    }
}

class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let url = anyURL()
        let (_, client) = makeSut(url: url)

        XCTAssertNil(client.requestedURL)
    }

    func test_load_requestsDataFromURL() {
        let url: URL = anyURL()
        let (sut, client) = makeSut(url: url)

        sut.fetchItems()

        XCTAssertEqual(client.requestedURL, url)
    }

    // MARK: Helpers:
    func makeSut(url: URL) -> (sut: RemoteFeedLoader, client: HttpClientSpy) {
        let client: HttpClientSpy = .init()
        let sut: RemoteFeedLoader = .init(url: url, client: client)
        return (sut, client)
    }

    func anyURL() -> URL {
        return URL(string: "http://any.url")!
    }
}
