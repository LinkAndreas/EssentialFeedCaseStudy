//  Copyright © 2021 Andreas Link. All rights reserved.

import XCTest

protocol FeedImageView {}

final class FeedImagePresenter {
    init(view: FeedImageView) {}
}

final class FeedImagePresenterTests: XCTestCase {
    func test_init_doesNotSendMessageToView() {
        let view = ViewSpy()
        _ = FeedImagePresenter(view: view)

        XCTAssertEqual(view.messages, [], "Expect no view messages")
    }

    // MARK: - Helpers
    final class ViewSpy: FeedImageView {
        enum Message: Hashable {}

        var messages: Set<Message> = []
    }
}
