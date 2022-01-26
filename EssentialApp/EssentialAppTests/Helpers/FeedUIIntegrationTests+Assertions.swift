//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import EssentialFeediOS
import XCTest

extension FeedUIIntegrationTests {
    func assertThat(
        _ sut: ListViewController,
        renders models: [FeedImage],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        sut.tableView.layoutIfNeeded()
        RunLoop.main.run(until: Date())

        let numberOfRenderedFeedImageViews: Int = sut.numberOfRenderedFeedImageViews()

        XCTAssertEqual(
            numberOfRenderedFeedImageViews,
            models.count,
            "Expected \(models.count) images, got \(numberOfRenderedFeedImageViews)",
            file: file,
            line: line
        )

        for (index, model) in models.enumerated() {
            assertThat(sut, hasViewConfiguredFor: model, atIndex: index, file: file, line: line)
        }
    }

    func assertThat(
        _ sut: ListViewController,
        hasViewConfiguredFor model: FeedImage,
        atIndex index: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = sut.feedImageView(atIndex: index)

        guard let cell = view as? FeedImageCell else {
            XCTFail("Expected \(FeedImageCell.self) instance, got \(String(describing: view))", file: file, line: line)
            return
        }

        let shouldLocationBeVisible: Bool = model.location != nil
        XCTAssertNotNil(view, file: file, line: line)
        XCTAssertEqual(
            cell.isShowingLocation,
            shouldLocationBeVisible,
            "Expected isShowingLocation to be \(shouldLocationBeVisible) for image view at index \(index)",
            file: file,
            line: line
        )
        XCTAssertEqual(
            cell.locationText,
            model.location,
            "Expected locationText to be \(String(describing: model.location)) for image view at index \(index)",
            file: file,
            line: line
        )
        XCTAssertEqual(
            cell.descriptionText,
            model.description,
            "Expected descriptionText to be \(String(describing: model.description)) for image view at index \(index)",
            file: file,
            line: line
        )
    }
}
