//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol HttpClient {
    func load(from url: URL, completion: @escaping (Error) -> Void)
}

public class RemoteFeedLoader {
    public enum Error: Swift.Error {
        case connectivity
    }

    private let url: URL
    private let client: HttpClient

    public init(url: URL, client: HttpClient) {
        self.url = url
        self.client = client
    }

    public func fetchItems(completion: @escaping (Error) -> Void) {
        client.load(from: url) { _ in
            completion(.connectivity)
        }
    }
}
