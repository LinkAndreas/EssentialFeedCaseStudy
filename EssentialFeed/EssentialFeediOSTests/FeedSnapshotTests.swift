//  Copyright © 2021 Andreas Link. All rights reserved.

import XCTest
import EssentialFeed
import EssentialFeediOS
import UIKit

final class FeedSnapshotTests: XCTestCase {
    func test_emptyFeed() {
        let sut = makeSUT()

        sut.display(emptyFeed())

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "EMPTY_FEED_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "EMPTY_FEED_dark")
    }

    func test_feedWithContent() {
        let sut = makeSUT()

        sut.display(feedWithContent())

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "FEED_WITH_CONTENT_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "FEED_WITH_CONTENT_dark")
    }

    func test_feedWithErrorMessage() {
        let sut = makeSUT()

        sut.display(.error(message: "This is a\nmulti-line\n error message."))

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "FEED_WITH_ERROR_MESSAGE_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "FEED_WITH_ERROR_MESSAGE_dark")
    }

    func test_feedWithFailedImageLoading() {
        let sut = makeSUT()

        sut.display(feedWithFailedImageLoading())

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "FEED_WITH_FAILED_IMAGE_LOADING_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "FEED_WITH_FAILED_IMAGE_LOADING_dark")
    }
}

private extension FeedViewController {
    func display(_ stubs: [ImageStub]) {
        let cells: [FeedImageCellController] = stubs.map { stub in
            let controller = FeedImageCellController(viewModel: stub.viewModel, delegate: stub)
            stub.controller = controller
            return controller
        }

        display(cells)
    }
}


private extension FeedSnapshotTests {
    func makeSUT() -> FeedViewController {
        let bundle = Bundle(for: FeedViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! FeedViewController
        controller.loadViewIfNeeded()
        controller.tableView.showsVerticalScrollIndicator = false
        controller.tableView.showsHorizontalScrollIndicator = false
        return controller
    }

    func record(snapshot: UIImage, named name: String, file: StaticString = #filePath, line: UInt = #line) {
        let snapshotURL = makeSnapshotURL(name: name, file: file, line: line)
        let snapshotData = makeSnapshotData(for: snapshot, file: file, line: line)

        do {
            try FileManager.default.createDirectory(
                at: snapshotURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
             )
            try snapshotData?.write(to: snapshotURL)
        } catch {
            return XCTFail("Failed to record snapshot with error: \(error)", file: file, line: line)
        }
    }

    func assert(snapshot: UIImage, named name: String, file: StaticString = #filePath, line: UInt = #line) {
        let snapshotURL = makeSnapshotURL(name: name, file: file, line: line)
        let snapshotData = makeSnapshotData(for: snapshot, file: file, line: line)

        guard let storedSnapshotData = try? Data(contentsOf: snapshotURL) else {
            return XCTFail("Failed to load snapshot at: \(snapshotURL). Use the record methos to store a snapshot before asserting.", file: file, line: line)
        }

        if snapshotData != storedSnapshotData {
            let temporarySnapshotURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(snapshotURL.lastPathComponent)

            try? snapshotData?.write(to: temporarySnapshotURL)

            XCTFail(
                "New snapshot does not match stored snapshot. New snapshot URL: \(temporarySnapshotURL), Stored snapshot URL \(snapshotURL)",
                file: file,
                line: line
            )
        }
    }

    func makeSnapshotData(for snapshot: UIImage, file: StaticString = #filePath, line: UInt = #line) -> Data? {
        guard let snapshotData = snapshot.pngData() else {
            XCTFail("Failed to generate PNG representation from snapshot", file: file, line: line)
            return nil
        }

        return snapshotData
    }

    func makeSnapshotURL(name: String, file: StaticString = #filePath, line: UInt = #line) -> URL {
        return URL(fileURLWithPath: String(describing: file))
            .deletingLastPathComponent()
            .appendingPathComponent("snapshots")
            .appendingPathComponent("\(name).png")
    }

    func emptyFeed() -> [FeedImageCellController] {
        return []
    }

    func feedWithContent() -> [ImageStub] {
        return [
            ImageStub(
                viewModel: FeedImageViewModel(
                    description: "Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
                    location: "Paris, France"
                ),
                image: UIImage.make(with: .red)
            ),
            ImageStub(
                viewModel: FeedImageViewModel(
                    description: "It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal distribution of letters, as opposed to using 'Content here, content here', making it look like readable English. Many desktop publishing packages and web page editors now use Lorem Ipsum as their default model text, and a search for 'lorem ipsum' will uncover many web sites still in their infancy.",
                    location: "Berlin, Germany"
                ),
                image: UIImage.make(with: .green)
            )
        ]
    }

    func feedWithFailedImageLoading() -> [ImageStub] {
        return [
            ImageStub(
                viewModel: FeedImageViewModel(
                    description: "Brandenburg Gare",
                    location: "Berlin, Germany"
                )
            ),
            ImageStub(
                viewModel: FeedImageViewModel(
                    description: "Eifel Tower",
                    location: "Paris, France"
                )
            )
        ]
    }
}

private class ImageStub: FeedImageCellControllerDelegate {
    weak var controller: FeedImageCellController?
    let viewModel: FeedImageViewModel
    let image: UIImage?

    init(viewModel: FeedImageViewModel, image: UIImage? = nil) {
        self.viewModel = viewModel
        self.image = image
    }

    func didRequestImage() {
        controller?.display(ResourceLoadingViewModel(isLoading: false))
        if let image = image {
            controller?.display(image)
            controller?.display(.noError)
        } else {
            controller?.display(.error(message: "any"))
        }
    }

    func didTriggerPreload() {}
    func didCancelLoad() {}
}

private extension UIViewController {
    func snapshot(for configuration: SnapshotConfiguration) -> UIImage {
        return SnapshotWindow(configuration: configuration, root: self).snapshot()
    }
}

private struct SnapshotConfiguration {
    let size: CGSize
    let safeAreaInsets: UIEdgeInsets
    let layoutMargins: UIEdgeInsets
    let traitCollection: UITraitCollection

    static func iPhone8(style: UIUserInterfaceStyle) -> SnapshotConfiguration {
        return SnapshotConfiguration(
            size: CGSize(width: 375, height: 667),
            safeAreaInsets: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0),
            layoutMargins: UIEdgeInsets(top: 20, left: 16, bottom: 0, right: 16),
            traitCollection: UITraitCollection(traitsFrom: [
                .init(forceTouchCapability: .available),
                .init(layoutDirection: .leftToRight),
                .init(preferredContentSizeCategory: .medium),
                .init(userInterfaceIdiom: .phone),
                .init(horizontalSizeClass: .compact),
                .init(verticalSizeClass: .regular),
                .init(displayScale: 2),
                .init(displayGamut: .P3),
                .init(userInterfaceStyle: style)
            ])
        )
    }
}

private final class SnapshotWindow: UIWindow {
    private var configuration: SnapshotConfiguration = .iPhone8(style: .light)

    convenience init(configuration: SnapshotConfiguration, root: UIViewController) {
        self.init(frame: CGRect(origin: .zero, size: configuration.size))
        self.configuration = configuration
        self.layoutMargins = configuration.layoutMargins
        self.rootViewController = root
        self.isHidden = false
        root.view.layoutMargins = configuration.layoutMargins
    }

    override var safeAreaInsets: UIEdgeInsets {
        return configuration.safeAreaInsets
    }

    override var traitCollection: UITraitCollection {
        return configuration.traitCollection
    }

    func snapshot() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds, format: .init(for: configuration.traitCollection))
        return renderer.image { actions in
            layer.render(in: actions.cgContext)
        }
    }
}
