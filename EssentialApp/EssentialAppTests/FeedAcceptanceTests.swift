//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import EssentialFeediOS
@testable import EssentialApp
import XCTest

class EssentialAppUIAcceptanceTests: XCTestCase {
    func test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity() {
        let feed = launch(httpClient: .online(response(for:)), store: .empty)

        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 2)
        XCTAssertEqual(feed.renderedFeedImageData(atIndex: 0), makeImageData())
        XCTAssertEqual(feed.renderedFeedImageData(atIndex: 1), makeImageData())
    }

    func test_onLaunch_displaysCachedFeedWhenCustomerHasNoConnectivity() {
        let sharedStore = InMemoryFeedStore.empty
        let onlineFeed = launch(httpClient: .online(response(for:)), store: sharedStore)

        onlineFeed.simulateFeedImageViewVisible(atIndex: 0)
        onlineFeed.simulateFeedImageViewVisible(atIndex: 1)

        let offlineFeed = launch(httpClient: .offline, store: sharedStore)

        XCTAssertEqual(offlineFeed.numberOfRenderedFeedImageViews(), 2)
        XCTAssertEqual(offlineFeed.renderedFeedImageData(atIndex: 0), makeImageData())
        XCTAssertEqual(offlineFeed.renderedFeedImageData(atIndex: 1), makeImageData())
    }

    func test_onLaunch_displaysEmptyFeedWhenCustomerHasNoConnectivityAndNoCache() {
        let feed = launch(httpClient: .offline, store: .empty)

        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 0)
    }

    func test_onEnteringBackground_deletesExpiredFeedCache() {
        let store = InMemoryFeedStore.withExpiredFeedCache

        enterBackground(with: store)

        XCTAssertNil(store.cachedFeed)
    }

    func test_onEnteringBackground_keepsNonExpiredFeedCache() {
        let store = InMemoryFeedStore.withNonExpiredFeedCache

        enterBackground(with: store)

        XCTAssertNotNil(store.cachedFeed)
    }
}

extension EssentialAppUIAcceptanceTests {
    private func launch(httpClient: HTTPClientStub = .offline, store: InMemoryFeedStore = .empty) -> FeedViewController {
        let sut = SceneDelegate(httpClient: httpClient, store: store)
        sut.window = UIWindow()
        sut.configureWindow()

        let root = sut.window?.rootViewController as? UINavigationController
        let feed = root?.topViewController as! FeedViewController
        return feed
    }

    private func enterBackground(with store: InMemoryFeedStore) {
        let sut = SceneDelegate(httpClient: HTTPClientStub.offline, store: store)
        sut.window = UIWindow()
        sut.configureWindow()
        sut.sceneWillResignActive(UIApplication.shared.connectedScenes.first!)
    }

    final class HTTPClientStub: HTTPClient {
        private class Task: HTTPClientTask {
            func cancel() {}
        }

        private let stub: (URL) -> HTTPClient.Result

        init(stub: @escaping (URL) -> HTTPClient.Result) {
            self.stub = stub
        }

        func load(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
            completion(stub(url))
            return Task()
        }

        static var offline: HTTPClientStub {
            return HTTPClientStub(stub: { _ in .failure(NSError(domain: "offline", code: 0))})
        }

        static func online(_ stub: @escaping (URL) -> (Data, HTTPURLResponse)) -> HTTPClientStub {
            return HTTPClientStub(stub: { url in .success(stub(url))})
        }
    }

    final class InMemoryFeedStore: FeedStore, FeedImageDataStore {
        private (set) var cachedFeed: CachedFeed?
        private var cachedImageData: [URL: Data]

        init(cachedFeed: CachedFeed? = nil, cachedImageData: [URL: Data] = [:]) {
            self.cachedFeed = cachedFeed
            self.cachedImageData = cachedImageData
        }

        func insert(feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
            self.cachedFeed = CachedFeed(feed: feed, timestamp: timestamp)
            completion(.success(()))
        }

        func retrieve(completion: @escaping RetrievalCompletion) {
            completion(.success(cachedFeed))
        }

        func deleteCachedFeed(completion: @escaping DeletionCompletion) {
            self.cachedFeed = nil
            completion(.success(()))
        }

        func insert(_ imageData: Data, for url: URL, completion: @escaping (FeedImageDataStore.InsertionResult) -> Void) {
            cachedImageData[url] = imageData
            completion(.success(()))
        }

        public func retrieve(dataForURL url: URL, completion: @escaping (FeedImageDataStore.RetrievalResult) -> Void) {
            completion(.success(cachedImageData[url]))
        }

        static var empty: InMemoryFeedStore {
            InMemoryFeedStore()
        }

        static var withExpiredFeedCache: InMemoryFeedStore {
            InMemoryFeedStore(cachedFeed: CachedFeed(feed: [], timestamp: Date.distantPast))
        }

        static var withNonExpiredFeedCache: InMemoryFeedStore {
            InMemoryFeedStore(cachedFeed: CachedFeed(feed: [], timestamp: Date()))
        }
    }

    private func response(for url: URL) -> (Data, HTTPURLResponse) {
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
        return UIImage.make(with: .red).pngData()!
    }

    private func makeFeedData() -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": [
            ["id": UUID().uuidString, "image": "http://image.com"],
            ["id": UUID().uuidString, "image": "http://image.com"]
        ]])
    }
}
