//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

final class URLProtocolStub: URLProtocol {
    private static let queue = DispatchQueue(label: "URLProtocolStub.queue")
    private static var _stub: Stub?
    private static var stub: Stub? {
        get { queue.sync { _stub } }
        set { queue.sync { _stub = newValue } }
    }

    public struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
        let requestObserver: ((URLRequest) -> Void)?

        init(
            data: Data? = nil,
            response: URLResponse? = nil,
            error: Error? = nil,
            requestObserver: ((URLRequest) -> Void)? = nil
        ) {
            self.data = data
            self.response = response
            self.error = error
            self.requestObserver = requestObserver
        }
    }

    static func stub(
        data: Data? = nil,
        response: URLResponse? = nil,
        error: Error? = nil
    ) {
        stub = .init(data: data, response: response, error: error, requestObserver: nil)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let stub = URLProtocolStub.stub else { return }

        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }

        if let response = stub.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }

        stub.requestObserver?(request)
    }

    override func stopLoading() {}

    static func observeRequests(observer: @escaping (URLRequest) -> Void) {
        stub = .init(data: nil, response: nil, error: nil, requestObserver: observer)
    }

    static func removeStub() {
        stub = nil
    }
}
