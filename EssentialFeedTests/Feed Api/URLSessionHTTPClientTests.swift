//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation
import EssentialFeed
import XCTest

protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask
}

protocol HTTPSessionTask {
    func resume()
}

class URLSessionHTTPClient {
    private let session: HTTPSession

    init(session: HTTPSession) {
        self.session = session
    }

    func load(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        session.dataTask(with: url) { data, response, error in }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    func test_loadFromURL_resumesDataTaskWithURL() {
        let url: URL = .init(string: "http://any-url.com")!
        let session: HTTPSessionSpy = .init()
        let task: HTTPSessionTaskSpy = .init()
        session.stub(url: url, with: .init(task: task))

        let sut: URLSessionHTTPClient = .init(session: session)

        sut.load(from: url) { _ in }

        XCTAssertEqual(task.resumeCallCount, 1)
    }

    // MARK: - Helpers
    private class HTTPSessionSpy: HTTPSession {
        private var dataTaskStubs: [URL: Stub] = [:]

        internal struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
            let task: HTTPSessionTask

            init(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil, task: HTTPSessionTask) {
                self.data = data
                self.response = response
                self.error = error
                self.task = task
            }
        }

        internal func dataTask(
            with url: URL,
            completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
        ) -> HTTPSessionTask {
            guard let stub = dataTaskStubs[url] else { fatalError("Did not found stub for requested url: \(url)") }

            completionHandler(stub.data, stub.response, stub.error)
            return stub.task
        }

        internal func stub(url: URL, with stub: Stub) {
            dataTaskStubs[url] = stub
        }
    }

    private class HTTPSessionTaskSpy: HTTPSessionTask {
        var resumeCallCount: UInt = 0

        func resume() {
            resumeCallCount += 1
        }
    }
}
