//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol HttpClient {
    func load(from url: URL)
}

public class RemoteFeedLoader {
    private let url: URL
    private let client: HttpClient

    public init(url: URL, client: HttpClient) {
        self.url = url
        self.client = client
    }

    public func fetchItems() {
        client.load(from: url)
    }
}
