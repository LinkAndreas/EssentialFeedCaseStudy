//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

class URLSessionHTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func load(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    func test_loadFromURL_failesOnRequestError() {
        URLProtocolStub.startInterceptingRequests()
        let url: URL = .init(string: "http://any-url.com")!
        let expectedError: NSError = .init(domain: "test_error", code: 42, userInfo: nil)
        URLProtocolStub.stub(url: url, data: nil, response: nil, error: expectedError)

        let sut: URLSessionHTTPClient = .init()
        let expectation = expectation(description: "Wait for load completion.")
        var capturedResults: [HTTPClient.Result] = []

        sut.load(from: url) { result in
            capturedResults.append(result)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(capturedResults.count, 1, "Expected one result, received \(capturedResults.count) results")

        switch capturedResults[0] {
        case let .failure(error as NSError):
            XCTAssertEqual(error.domain, expectedError.domain)

        default:
            XCTFail("Wrong result")
        }

        URLProtocolStub.stopInterceptingRequests()
    }

    // MARK: - Helpers
    private class URLProtocolStub: URLProtocol {
        private static var stubs: [URL: Stub] = [:]

        internal struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?

            init(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil) {
                self.data = data
                self.response = response
                self.error = error
            }
        }

        internal static func stub(
            url: URL,
            data: Data? = nil,
            response: URLResponse? = nil,
            error: Error? = nil
        ) {
            stubs[url] = .init(data: data, response: response, error: error)
        }

        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else { return false }

            return stubs[url] != nil
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            guard let url = request.url, let stub = Self.stubs[url] else { return }

            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}

        static func startInterceptingRequests() {
            URLProtocol.registerClass(Self.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(Self.self)
        }
    }
}
