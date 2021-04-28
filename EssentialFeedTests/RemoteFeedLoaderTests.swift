//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

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

        let error = NSError(domain: "domain", code: 42, userInfo: nil)
        var capturedErrors: [RemoteFeedLoader.Error] = []
        sut.fetchItems { capturedErrors.append($0) }
        client.complete(with: error)

        XCTAssertEqual(capturedErrors, [.connectivity])
    }

    // MARK: Helpers:
    class HttpClientSpy: HttpClient {
        var messages: [(url: URL, completion: (Error) -> Void)] = []
        var requestedURLs: [URL] { messages.map(\.url) }

        func load(from url: URL, completion: @escaping (Error) -> Void) {
            messages.append((url, completion))
        }

        func complete(with error: Error, atIndex index: Int = 0) {
            messages[index].completion(error)
        }
    }

    func makeSut(url: URL) -> (sut: RemoteFeedLoader, client: HttpClientSpy) {
        let client: HttpClientSpy = .init()
        let sut: RemoteFeedLoader = .init(url: url, client: client)
        return (sut, client)
    }

    func anyURL() -> URL {
        return URL(string: "http://any.url")!
    }
}
