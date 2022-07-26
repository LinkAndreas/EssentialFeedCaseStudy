//  Copyright © 2022 Andreas Link. All rights reserved.

import EssentialFeed
import EssentialFeediOS
import XCTest

extension CommentsUIIntegrationTests {
    func assertThat(
        _ sut: ListViewController,
        renders comments: [ImageComment],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        sut.tableView.layoutIfNeeded()
        RunLoop.main.run(until: Date())

        let viewModels = ImageCommentsPresenter.map(comments)
        let numberOfRenderedComments: Int = sut.numberOfRenderedComments()

        XCTAssertEqual(
            numberOfRenderedComments,
            comments.count,
            "Expected \(comments.count) comments, got \(numberOfRenderedComments)",
            file: file,
            line: line
        )

        viewModels.comments.enumerated().forEach { index, model in
            XCTAssertEqual(sut.commentMessage(at: index), model.message, "message at \(index)", file: file, line: line)
            XCTAssertEqual(sut.commentDate(at: index), model.date, "message at \(index)", file: file, line: line)
            XCTAssertEqual(sut.commentUsername(at: index), model.username, "message at \(index)", file: file, line: line)
        }
    }
}
