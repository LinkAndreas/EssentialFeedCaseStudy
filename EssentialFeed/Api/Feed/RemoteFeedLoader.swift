//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol HttpClient {
    func load(from url: URL, completion: (Error) -> Void)
}

public class RemoteFeedLoader {
    private let url: URL
    private let client: HttpClient

    public init(url: URL, client: HttpClient) {
        self.url = url
        self.client = client
    }

    public func fetchItems(completion: (Error) -> Void) {
        client.load(from: url, completion: completion)
    }
}
