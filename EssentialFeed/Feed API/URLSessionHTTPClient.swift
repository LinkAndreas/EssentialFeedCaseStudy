//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private enum Error: Swift.Error, Equatable {
        case invalidResponse
    }

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func load(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        session.dataTask(with: url) { data, response, error in
            switch (data, (response as? HTTPURLResponse), error) {
            case let (data?, response?, nil):
                completion(.success((data, response)))

            case let (nil, nil, error?):
                completion(.failure(error))

            default:
                completion(.failure(Error.invalidResponse))
            }
        }.resume()
    }
}
