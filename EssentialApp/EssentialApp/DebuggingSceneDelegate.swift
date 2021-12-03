//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import UIKit

#if DEBUG
final class DebuggingSceneDelegate: SceneDelegate {
    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)
        
        if CommandLine.arguments.contains("-reset") {
            try? FileManager.default.removeItem(at: localStoreURL)
        }
    }

    override func makeRemoteClient() -> HTTPClient {
        if let connectivity = UserDefaults.standard.string(forKey: "connectivity") {
            return DebuggingHTTPClient(connectivity: connectivity)
        }else {
            return super.makeRemoteClient()
        }
    }
}

final class DebuggingHTTPClient: HTTPClient {
    private class Task: HTTPClientTask {
        func cancel() {}
    }

    private let connectivity: String

    init(connectivity: String) {
        self.connectivity = connectivity
    }

    func load(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        switch connectivity {
        case "online":
            completion(.success(makeSuccessfulResponse(for: url)))
        default:
            completion(.failure(NSError(domain: "offline", code: 0)))
        }

        return Task()
    }

    private func makeSuccessfulResponse(for url: URL) -> (Data, HTTPURLResponse) {
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (makeData(for: url), response)
        }

        private func makeData(for url: URL) -> Data {
            switch url.absoluteString {
            case "http://image.com":
                return makeImageData()

            default:
                return makeFeedData()
            }
        }

        private func makeImageData() -> Data {
            let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
            UIGraphicsBeginImageContext(rect.size)
            let context = UIGraphicsGetCurrentContext()!
            context.setFillColor(UIColor.red.cgColor)
            context.fill(rect)
            let img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return img!.pngData()!
        }

        private func makeFeedData() -> Data {
            return try! JSONSerialization.data(withJSONObject: ["items": [
                ["id": UUID().uuidString, "image": "http://image.com"],
                ["id": UUID().uuidString, "image": "http://image.com"]
            ]])
        }
}
#endif

