//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class FeedImagePresenterTests: XCTestCase {
    func test_map_createsViewModel() {
        let image = anyFeedImage()
        let viewModel = FeedImagePresenter.map(image)

        XCTAssertEqual(viewModel.location, image.location)
        XCTAssertEqual(viewModel.description, image.description)
    }

    // MARK: - Helpers

    struct AnyImage: Hashable {}

    private func anyFeedImage(description: String = "anyDescription", location: String = "anyLocation") -> FeedImage {
        return .init(id: UUID(), description: description, location: location, url: anyURL())
    }
}
