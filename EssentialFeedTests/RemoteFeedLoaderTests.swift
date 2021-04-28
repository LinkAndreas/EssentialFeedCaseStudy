//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

class HttpClientSpy: HttpClient {
    var error: Error?
    var requestedURLs: [URL] = []

    func load(from url: URL, completion: (Error) -> Void) {
        requestedURLs.append(url)

        if let error = error {
            completion(error)
        }
    }
}

class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let url = anyURL()
        let (_, client) = makeSut(url: url)

        XCTAssertEqual(client.requestedURLs, [])
    }

    func test_load_requestsDataFromURL() {
        let url: URL = anyURL()
        let (sut, client) = makeSut(url: url)

        sut.fetchItems { _ in }

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURLTwice() {
        let url: URL = anyURL()
        let (sut, client) = makeSut(url: url)

        sut.fetchItems { _ in }
        sut.fetchItems { _ in }

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        let url: URL = anyURL()
        let (sut, client) = makeSut(url: url)

        client.error = NSError(domain: "domain", code: 42, userInfo: nil)
        var capturedErrors: [RemoteFeedLoader.Error] = []
        sut.fetchItems { capturedErrors.append($0) }

        XCTAssertEqual(capturedErrors, [.connectivity])
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
