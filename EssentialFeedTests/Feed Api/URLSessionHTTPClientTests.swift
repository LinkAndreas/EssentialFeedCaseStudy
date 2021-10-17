//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class URLSessionHTTPClientTests: XCTestCase {
    override func tearDown() {
        URLProtocolStub.removeStub()
    }

    func test_loadFromURL_performsGETRequestWithURL() {
        let url: URL = anyURL()
        let sut = makeSUT()

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
        let sut = makeSUT()
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

    func test_cancelGetFromURLTask_cancelsURLRequest() {
        let receivedError = resultErrorFor(taskHandler: { $0.cancel() }) as NSError?

        XCTAssertEqual(receivedError?.code, URLError.cancelled.rawValue)
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
        data: Data? = nil,
        response: URLResponse? = nil,
        error: Error? = nil,
        taskHandler: (HTTPClientTask) -> Void = { _ in },
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        guard case let .failure(error) = resultFor(
            data: data,
            response: response,
            error: error,
            taskHandler: taskHandler
        ) else {
            XCTFail("Expected to receive error response.", file: file, line: line)
            return nil
        }

        return error
    }

    private func resultFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        taskHandler: (HTTPClientTask) -> Void = { _ in },
        file: StaticString = #file,
        line: UInt = #line
    ) -> HTTPClient.Result? {
        let sut = makeSUT()
        let url: URL = anyURL()

        URLProtocolStub.stub(data: data, response: response, error: error)

        let expectation = expectation(description: "Wait for load completion.")
        var capturedResult: HTTPClient.Result?

        taskHandler(sut.load(from: url) { result in
            capturedResult = result
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 1.0)

        return capturedResult
    }

    func makeSUT() -> HTTPClient {
        let configuration: URLSessionConfiguration = .ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut: URLSessionHTTPClient = .init(session: session)
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
