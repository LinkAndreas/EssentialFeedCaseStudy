//  Copyright © 2022 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class FeedEndpointTests: XCTestCase {
    func test_feed_endpointURL() {
        let baseURL = URL(string: "http://base-url.com/")!
        let sut = FeedEndpoint.get()
        
        let received = sut.url(baseURL: baseURL)
        
        XCTAssertEqual(received.scheme, "http", "scheme")
        XCTAssertEqual(received.host, "base-url.com", "host")
        XCTAssertEqual(received.path, "/v1/feed", "path")
        XCTAssertEqual(received.query, "limit=10", "query")
    }
    
    func test_feed_endpointURLAfterGivenImage() {
        let image = uniqueImage()
        let baseURL = URL(string: "http://base-url.com/")!
        let sut = FeedEndpoint.get(after: image)
        
        let received = sut.url(baseURL: baseURL)

        XCTAssertEqual(received.scheme, "http", "scheme")
        XCTAssertEqual(received.host, "base-url.com", "host")
        XCTAssertEqual(received.path, "/v1/feed", "path")
        XCTAssertEqual(received.query?.contains("limit=10"), true, "limit query param")
        XCTAssertEqual(received.query?.contains("after_id=\(image.id)"), true, "after_id query param")
    }
}

extension FeedEndpointTests {
    private func image(with id: UUID) -> FeedImage {
        FeedImage(id: id, description: nil, location: nil, url: anyURL())
    }
    
    private func anyImageId() -> UUID {
        UUID()
    }
}
