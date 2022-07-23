//  Copyright © 2022 Andreas Link. All rights reserved.

public struct ImageCommentsViewModel: Hashable {
    public let comments: [ImageCommentViewModel]

    public init(comments: [ImageCommentViewModel]) {
        self.comments = comments
    }
}

public struct ImageCommentViewModel: Hashable {
    public let message: String
    public let date: String
    public let username: String

    public init(message: String, date: String, username: String) {
        self.message = message
        self.date = date
        self.username = username
    }
}
