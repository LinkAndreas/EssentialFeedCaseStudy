//  Copyright © 2022 Andreas Link. All rights reserved.

import Foundation

public final class RemoteLoader<Resource> {
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public typealias Result = Swift.Result<Resource, Swift.Error>
    public typealias Mapper = (Data, HTTPURLResponse) throws -> Resource

    private let url: URL
    private let client: HTTPClient
    private let mapper: Mapper

    public init(url: URL, client: HTTPClient, mapper: @escaping Mapper) {
        self.url = url
        self.client = client
        self.mapper = mapper
    }

    public func load(completion: @escaping (Result) -> Void) {
        client.load(from: url) { [weak self] response in
            guard let self = self else { return }

            switch response {
            case let .success((data, response)):
                completion(self.map(data: data, response: response))

            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }

    func map(data: Data, response: HTTPURLResponse) -> Result {
        do {
            return .success(try mapper(data, response))
        } catch {
            return .failure(Error.invalidData)
        }
    }
}
