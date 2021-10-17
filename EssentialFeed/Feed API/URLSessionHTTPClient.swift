//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation


public class URLSessionHTTPClient: HTTPClient {
    private enum Error: Swift.Error, Equatable {
        case invalidResponse
    }

    private class URLSessionDataTaskWrapper: HTTPClientTask {
        private let task: URLSessionDataTask

        public init(task: URLSessionDataTask) {
            self.task = task
        }

        public func cancel() {
            task.cancel()
        }
    }

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    @discardableResult
    public func load(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        let task: URLSessionDataTask = session.dataTask(with: url) { data, response, error in
            switch (data, (response as? HTTPURLResponse), error) {
            case let (data?, response?, nil):
                completion(.success((data, response)))

            case let (nil, nil, error?):
                completion(.failure(error))

            default:
                completion(.failure(Error.invalidResponse))
            }
        }

        task.resume()
        return URLSessionDataTaskWrapper(task: task)
    }
}
