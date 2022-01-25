//  Copyright © 2022 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class ImageCommentsLocalizationTests: XCTestCase {
    func test_title_isLocalized() {
        let table = "ImageComments"
        let bundle = Bundle(for: ImageCommentsPresenter.self)

        assertLocalizedKeyAndValuesExist(in: bundle, and: table)
    }
}
