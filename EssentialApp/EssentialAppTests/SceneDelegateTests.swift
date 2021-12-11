//  Copyright © 2021 Andreas Link. All rights reserved.

@testable import EssentialApp
import EssentialFeediOS
import XCTest

final class SceneDelegateTests: XCTestCase {
    func test_configureWindow_setsWindowAsKeyAndVisible() {
        let window = UIWindowSpy()
        let sut = SceneDelegate()
        sut.window = window

        sut.configureWindow()

        XCTAssertEqual(window.makeKeyAndVisibleCallCount, 1, "Expected to make window key and visible.")
    }

    func test_configureWindow_configuresRootViewController() {
        let window = UIWindow()
        let sut = SceneDelegate()
        sut.window = window

        sut.configureWindow()

        let root = sut.window?.rootViewController
        let navigationController = root as? UINavigationController
        let topViewController = navigationController?.topViewController

        XCTAssertTrue(
            root is UINavigationController,
            "Expected UINavigationController as root, got \(String(describing: root)) instead."
        )

        XCTAssertTrue(
            topViewController is FeedViewController,
            "Expected \(String(describing: FeedViewController.self)) as topViewController, got \(String(describing: topViewController)) instead."
        )
    }
}

private extension SceneDelegateTests {
    final class UIWindowSpy: UIWindow {
        private (set) var makeKeyAndVisibleCallCount: Int = 0

        override func makeKeyAndVisible() {
            makeKeyAndVisibleCallCount += 1
        }
    }
}
