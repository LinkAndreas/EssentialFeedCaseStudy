//  Copyright © 2022 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class SharedLocalizationTests: XCTestCase {
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "Shared"
        let bundle = Bundle(for: LoadResourcePresenter<Any, DummyView>.self)
        assertLocalizedKeyAndValuesExist(in: bundle, and: table)
    }

    // MARK: - Helpers
    private class DummyView: ResourceView {
        func display(_ viewModel: Any) {}
    }
}
