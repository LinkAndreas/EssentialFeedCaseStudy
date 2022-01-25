//  Copyright © 2022 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class ImageCommentsPresenterTests: XCTestCase {
    func test_title() {
        XCTAssertEqual(
            ImageCommentsPresenter.title,
            localized("IMAGE_COMMENTS_VIEW_TITLE", table: "ImageComments", bundle: Bundle(for: ImageCommentsPresenter.self))
        )
    }
}
