//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class FeedPresenterTests: XCTestCase {
    func test_title_isLocalized() {
        XCTAssertEqual(
            FeedPresenter.title,
            localized("FEED_VIEW_TITLE", table: "Feed", bundle: Bundle(for: FeedPresenter.self))
        )
    }

    func test_map_createsViewModel() {
        let feed = uniqueImageFeed().models
        let viewModel = FeedPresenter.map(feed)

        XCTAssertEqual(viewModel.feed, feed)
    }
}
