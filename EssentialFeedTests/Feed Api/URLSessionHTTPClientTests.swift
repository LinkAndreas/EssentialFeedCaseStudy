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
    override func setUp() {
        URLProtocolStub.startInterceptingRequests()
    }

    override func tearDown() {
        URLProtocolStub.stopInterceptingRequests()
    }

    func test_loadFromURL_performsGETRequestWithURL() {
        let url: URL = anyURL()
        let sut = makeSut()
        let expectation = expectation(description: "Wait for request")

        var receivedRequest: URLRequest?
        URLProtocolStub.observeRequests { request in
            receivedRequest = request
            expectation.fulfill()
        }

        sut.load(from: url) { _ in }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertNotNil(receivedRequest)
        XCTAssertEqual(receivedRequest?.url, url)
        XCTAssertEqual(receivedRequest?.httpMethod, "GET")
    }
    
    func test_loadFromURL_failesOnRequestError() {
        let expectedError: NSError = .init(domain: "test_error", code: 42, userInfo: nil)
        let receivedError: NSError? = resultErrorFor(data: nil, response: nil, error: expectedError) as NSError?

        XCTAssertEqual(receivedError?.domain, expectedError.domain)
        XCTAssertEqual(receivedError?.code, expectedError.code)
    }


    func test_loadFromURL_succeedsOnHTTPUrlResponseWithData() {
        let sut = makeSut()
        let url: URL = anyURL()
        let expectedData: Data = anyData()
        let expectedResponse: HTTPURLResponse = anyHttpResponse()

        URLProtocolStub.stub(data: expectedData, response: expectedResponse, error: nil)

        let expectation = expectation(description: "Wait for load completion.")
        var capturedResult: HTTPClient.Result?

        sut.load(from: url) { result in
            capturedResult = result
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        switch capturedResult {
        case let .success((recivedData, receivedResponse)):
            XCTAssertEqual(expectedData, recivedData)
            XCTAssertEqual(expectedResponse.url, receivedResponse.url)
            XCTAssertEqual(expectedResponse.statusCode, receivedResponse.statusCode)

        default:
            XCTFail("Expected successful result")
        }
    }


        default:
            XCTFail("Wrong result")
        }
    }

    // MARK: - Helpers
    private func resultErrorFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        let sut = makeSut()
        let url: URL = anyURL()

        URLProtocolStub.stub(data: data, response: response, error: error)

        let expectation = expectation(description: "Wait for load completion.")
        var capturedResult: HTTPClient.Result?

        sut.load(from: url) { result in
            capturedResult = result
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        switch capturedResult {
        case let .failure(error):
            return error

        case .success, .none:
            return nil
        }
    }

    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?

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
            data: Data? = nil,
            response: URLResponse? = nil,
            error: Error? = nil
        ) {
            stub = .init(data: data, response: response, error: error)
        }

        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }


        override func startLoading() {
            if let data = Self.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = Self.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let error = Self.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
        }

        override func stopLoading() {}

        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }

        static func startInterceptingRequests() {
            URLProtocol.registerClass(Self.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(Self.self)
            stub = nil
            requestObserver = nil
        }
    }

    func makeSut() -> URLSessionHTTPClient {
        let sut: URLSessionHTTPClient = .init()
        trackForMemoryLeaks(sut)
        return sut
    }

    func anyURL() -> URL {
        return URL(string: "http://any.url")!
    }
}