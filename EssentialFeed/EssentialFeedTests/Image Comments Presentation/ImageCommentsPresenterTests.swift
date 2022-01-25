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

    func test_map_createsViewModels() {
        let now = Date()
        let locale = Locale(identifier: "en_US_POSIX")
        let calendar = Calendar(identifier: .gregorian)

        let comments = [
            makeComment(
                message: "message",
                createdAt: now.adding(minutes: -5, calendar: calendar),
                username: "username"
            ),
            makeComment(
                message: "another message",
                createdAt: now.adding(days: -1, calendar: calendar),
                username: "another username"
            )
        ]
        let viewModel = ImageCommentsPresenter.map(comments, currentDate: now, locale: locale, calendar: calendar)

        XCTAssertEqual(viewModel.comments, [
            ImageCommentViewModel(
                message: "message",
                date: "5 minutes ago",
                username: "username"
            ),
            ImageCommentViewModel(
                message: "another message",
                date: "1 day ago",
                username: "another username"
            )
        ])
    }

    // MARK: - Helpers

    func makeComment(message: String, createdAt: Date, username: String) -> ImageComment {
        ImageComment(id: UUID(), message: message, createdAt: createdAt, username: username)
    }
}
