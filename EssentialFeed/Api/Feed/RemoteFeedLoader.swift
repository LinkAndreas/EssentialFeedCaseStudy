//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

protocol HttpClient {
    func load(from url: URL)
}

class RemoteFeedLoader {
    let url: URL
    let client: HttpClient

    init(url: URL, client: HttpClient) {
        self.url = url
        self.client = client
    }

    func fetchItems() {
        client.load(from: url)
    }
}
