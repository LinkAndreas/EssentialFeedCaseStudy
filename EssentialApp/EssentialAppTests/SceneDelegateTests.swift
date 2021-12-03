//  Copyright © 2021 Andreas Link. All rights reserved.

@testable import EssentialApp
import EssentialFeediOS
import XCTest

final class SceneDelegateTests: XCTestCase {
    func test_willConnectToScene_configuresRootViewController() {
        let sut = SceneDelegate()
        sut.window = UIWindow()

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
