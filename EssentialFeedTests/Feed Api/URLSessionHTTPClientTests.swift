//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

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

        let exp = expectation(description: "Wait for observer")
        var receivedRequests: [URLRequest] = []
        URLProtocolStub.observeRequests { request in
            receivedRequests.append(request)
            exp.fulfill()
        }

        let exp2 = expectation(description: "Wait for request")
        sut.load(from: url) { _ in exp2.fulfill() }

        wait(for: [exp, exp2], timeout: 1.0)

        XCTAssertEqual(receivedRequests.count, 1)
        XCTAssertEqual(receivedRequests.first?.url, url)
        XCTAssertEqual(receivedRequests.first?.httpMethod, "GET")
    }
    
    func test_loadFromURL_failesOnRequestError() {
        let expectedError: NSError = .init(domain: "test_error", code: 42, userInfo: nil)
        let receivedError: NSError? = resultErrorFor(data: nil, response: nil, error: expectedError) as NSError?

        XCTAssertEqual(receivedError?.domain, expectedError.domain)
        XCTAssertEqual(receivedError?.code, expectedError.code)
    }

    func test_loadFromURL_failesOnAllInvalidRepresentations() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyNonHttpResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyNonHttpResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHttpResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyNonHttpResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHttpResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyNonHttpResponse(), error: nil))
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

    func test_loadFromURL_succeedsWithEmptyDataOnHTTPUrlResponseWithNilData() {
        let expectedResponse: HTTPURLResponse = anyHttpResponse()
        let receivedValues = resultValuesFor(data: nil, response: expectedResponse, error: nil)

        let emptyData: Data = .init()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, expectedResponse.url)
        XCTAssertEqual(receivedValues?.response.statusCode, expectedResponse.statusCode)
    }

    // MARK: - Helpers
    private func resultValuesFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (data: Data, response: HTTPURLResponse)? {
        guard case let .success((data, response)) = resultFor(data: data, response: response, error: error) else {
            XCTFail("Expected to receive successful response.", file: file, line: line)
            return nil
        }

        return (data, response)
    }

    private func resultErrorFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        guard case let .failure(error) = resultFor(data: data, response: response, error: error) else {
            XCTFail("Expected to receive error response.", file: file, line: line)
            return nil
        }

        return error
    }

    private func resultFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #file,
        line: UInt = #line
    ) -> HTTPClient.Result? {
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

        return capturedResult
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
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }


        override func startLoading() {
            if let requestObserver = Self.requestObserver {
                client?.urlProtocolDidFinishLoading(self)
                return requestObserver(request)
            }

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

    func makeSut() -> HTTPClient {
        let sut: URLSessionHTTPClient = .init()
        trackForMemoryLeaks(sut)
        return sut
    }

    func anyNonHttpResponse() -> URLResponse {
        return .init(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }

    func anyHttpResponse() -> HTTPURLResponse {
        return .init(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    func anyData() -> Data {
        return "anyData".data(using: .utf8)!
    }
}
