//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import EssentialFeediOS
@testable import EssentialApp
import XCTest

class EssentialAppUIAcceptanceTests: XCTestCase {
    func test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity() {
        let feed = launch(httpClient: .online(response(for:)), store: .empty)

        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 2)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData1())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData2())
        XCTAssertEqual(feed.canLoadMore, true)
        
        feed.simulateLoadMoreFeedAction()
        
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 3)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData1())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData2())
        XCTAssertEqual(feed.renderedFeedImageData(at: 2), makeImageData3())
        XCTAssertEqual(feed.canLoadMore, true)
        
        feed.simulateLoadMoreFeedAction()

        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 3)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData1())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData2())
        XCTAssertEqual(feed.renderedFeedImageData(at: 2), makeImageData3())
        XCTAssertEqual(feed.canLoadMore, false)
    }

    func test_onLaunch_displaysCachedFeedWhenCustomerHasNoConnectivity() {
        let sharedStore = InMemoryFeedStore.empty
        let onlineFeed = launch(httpClient: .online(response(for:)), store: sharedStore)

        onlineFeed.simulateFeedImageViewVisible(at: 0)
        onlineFeed.simulateFeedImageViewVisible(at: 1)

        let offlineFeed = launch(httpClient: .offline, store: sharedStore)

        XCTAssertEqual(offlineFeed.numberOfRenderedFeedImageViews(), 2)
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 0), makeImageData1())
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 1), makeImageData2())
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

    func test_onFeedImageSelection_displayComments() {
        let comments = showCommentsForFirstImage()

        XCTAssertEqual(comments.numberOfRenderedComments(), 1)
        XCTAssertEqual(comments.commentMessage(at: 0), makeCommentMessage())
    }
}

extension EssentialAppUIAcceptanceTests {
    private func launch(httpClient: HTTPClientStub = .offline, store: InMemoryFeedStore = .empty) -> ListViewController {
        let sut = SceneDelegate(httpClient: httpClient, store: store)
        sut.window = UIWindow()
        sut.configureWindow()

        let root = sut.window?.rootViewController as? UINavigationController
        let feed = root?.topViewController as! ListViewController
        return feed
    }

    private func showCommentsForFirstImage() -> ListViewController {
        let feed = launch(httpClient: .online(response), store: .empty)

        feed.simulateTapOnFeedImage(at: 0)
        RunLoop.current.run(until: Date())

        let nav = feed.navigationController
        let comments = nav?.topViewController as! ListViewController
        return comments
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
        switch url.path {
        case "/image-0": return makeImageData1()
        case "/image-1": return makeImageData2()
        case "/image-2": return makeImageData3()

        case "/essential-feed/v1/feed" where url.query?.contains("after_id") == false:
            return makeFirstFeedPageData()
            
        case "/essential-feed/v1/feed" where url.query?.contains("after_id=A28F5FE3-27A7-44E9-8DF5-53742D0E4A5A") == true:
            return makeSecondFeedPageData()
            
        case "/essential-feed/v1/feed" where url.query?.contains("after_id=166FCDD7-C9F4-420A-B2D6-CE2EAFA3D82F") == true:
            return makeLastFeedPageData()

        case "/essential-feed/v1/image/2AB2AE66-A4B7-4A16-B374-51BBAC8DB086/comments":
            return makeCommentsData()

        default:
            return Data()
        }
    }

    private func makeImageData1() -> Data { UIImage.make(with: .red).pngData()! }
    private func makeImageData2() -> Data { UIImage.make(with: .red).pngData()! }
    private func makeImageData3() -> Data { UIImage.make(with: .red).pngData()! }

    private func makeFirstFeedPageData() -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": [
            ["id": "2AB2AE66-A4B7-4A16-B374-51BBAC8DB086", "image": "http://feed.com/image-0"],
            ["id": "A28F5FE3-27A7-44E9-8DF5-53742D0E4A5A", "image": "http://feed.com/image-1"]
        ]])
    }
    
    private func makeSecondFeedPageData() -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": [
            ["id": "166FCDD7-C9F4-420A-B2D6-CE2EAFA3D82F", "image": "http://feed.com/image-2"]
        ]])
    }
    
    private func makeLastFeedPageData() -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": []])
    }

    private func makeCommentsData() -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": [
            [
                "id": UUID().uuidString,
                "message": makeCommentMessage(),
                "created_at": "2020-05-20T11:24:59+0000",
                "author": ["username": "a username"]
            ]
        ]])
    }

    private func makeCommentMessage() -> String {
        return "a message"
    }
}
