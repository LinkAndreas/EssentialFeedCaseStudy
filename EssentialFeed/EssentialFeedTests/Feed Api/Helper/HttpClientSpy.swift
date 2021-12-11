//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed

class HttpClientSpy: HTTPClient {
    private struct Task: HTTPClientTask {
        private let onCancel: (() -> Void)?

        init(onCancel: (() -> Void)? = nil) {
            self.onCancel = onCancel
        }

        func cancel() {
            onCancel?()
        }
    }

    var messages: [(url: URL, completion: (Result<(Data, HTTPURLResponse), Error>) -> Void)] = []
    var requestedURLs: [URL] { messages.map(\.url) }
    private(set) var cancelledURLs = [URL]()

    func load(from url: URL, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void) -> HTTPClientTask {
        messages.append((url, completion))
        return Task { [weak self] in  self?.cancelledURLs.append(url) }
    }

    func complete(with error: Error, atIndex index: Int = 0) {
        messages[index].completion(.failure(error))
    }

    func complete(withStatusCode statusCode: Int, data: Data, atIndex index: Int = 0) {
        let response = HTTPURLResponse(
            url: requestedURLs[index],
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!

        messages[index].completion(.success((data, response)))
    }
}
