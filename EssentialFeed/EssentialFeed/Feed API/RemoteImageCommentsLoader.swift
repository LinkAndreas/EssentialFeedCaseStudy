//  Copyright © 2022 Andreas Link. All rights reserved.

import Foundation

public final class RemoteImageCommentsLoader {
    public typealias Result = Swift.Result<[ImageComment], Swift.Error>

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    private let url: URL
    private let client: HTTPClient

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (Result) -> Void) {
        client.load(from: url) { [weak self] response in
            guard self != nil else { return }

            switch response {
            case let .success((data, response)):
                completion(RemoteImageCommentsLoader.map(data: data, response: response))

            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }

    static func map(data: Data, response: HTTPURLResponse) -> Result {
        do {
            let items = try ImageCommentsMapper.map(data: data, response: response)
            return .success(items)
        } catch {
            return .failure(error)
        }
    }
}
