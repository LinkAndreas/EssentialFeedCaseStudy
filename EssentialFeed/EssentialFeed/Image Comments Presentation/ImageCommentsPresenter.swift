//  Copyright © 2022 Andreas Link. All rights reserved.

import Foundation

public final class ImageCommentsPresenter {
    public static var title: String {
        return NSLocalizedString(
            "IMAGE_COMMENTS_VIEW_TITLE",
            tableName: "ImageComments",
            bundle: Bundle(for: Self.self),
            comment: "Title for the image comments view"
        )
    }

    public static func map(
        _ comments: [ImageComment],
        currentDate: Date = Date(),
        locale: Locale = .current,
        calendar: Calendar = .current
    ) -> ImageCommentsViewModel {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.calendar = calendar

        return ImageCommentsViewModel(
            comments: comments.map { comment in
                ImageCommentViewModel(
                    message: comment.message,
                    date: formatter
                        .localizedString(for: comment.createdAt, relativeTo: currentDate),
                    username: comment.username
                )
            }
        )
    }
}
