//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed

class HttpClientSpy: HTTPClient {
    var messages: [(url: URL, completion: (Result<(Data, HTTPURLResponse), Error>) -> Void)] = []
    var requestedURLs: [URL] { messages.map(\.url) }

    func load(from url: URL, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void) {
        messages.append((url, completion))
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
