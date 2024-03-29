//  Copyright © 2021 Andreas Link. All rights reserved.

import Combine
import CoreData
import EssentialFeed
import EssentialFeediOS
import os
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private lazy var scheduler = DispatchQueue(
        label: "de.linkandreas.EssentialApp.infra.queue",
        qos: .userInitiated,
        attributes: .concurrent
    ).eraseToAnyScheduler()

    private lazy var logger: Logger = Logger(subsystem: "de.linkandreas.EssentialApp", category: "main")
    private lazy var baseURL = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed")!

    private lazy var httpClient: HTTPClient = {
        URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
    }()

    private lazy var store: FeedStore & FeedImageDataStore = {
        do {
            return try CoreDataFeedStore(
                storeURL: NSPersistentContainer
                    .defaultDirectoryURL()
                    .appendingPathComponent("feed-store.sqlite")
            )
        } catch {
            assertionFailure("Failed to instantiate CoreDataFeedStore, error occurred: \(error.localizedDescription)")
            logger.fault("Failed to instantiate CoreDataFeedStore, error occurred: \(error.localizedDescription)")
            return NullStore()
        }
    }()

    private lazy var navigationController = UINavigationController(
        rootViewController: FeedUIComposer.feedComposedWith(
            feedLoader: makeRemoteFeedLoaderWithLocalFallback,
            imageLoader: makeLocalImageLoaderWithRemoteFallback(url:),
            selection: showComments
        )
    )

    private lazy var localFeedLoader = LocalFeedLoader(store: store, currentDate: Date.init)
    private lazy var localImageLoader = LocalFeedImageDataLoader(store: store)

    convenience init(
        httpClient: HTTPClient,
        store: FeedStore & FeedImageDataStore,
        scheduler: AnyDispatchQueueScheduler
    ) {
        self.init()
        self.httpClient = httpClient
        self.store = store
        self.scheduler = scheduler
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        configureWindow()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        localFeedLoader.validateCache { _ in }
    }

    func configureWindow() {
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }

    private func showComments(for image: FeedImage) {
        let url = ImageCommentsEndpoint.get(image.id).url(baseURL: baseURL)
        let comments = CommentsUIComposer.commentsComposedWith(commentsLoader: makeRemoteCommentsLoader(url: url))
        navigationController.pushViewController(comments, animated: true)
    }

    private func makeRemoteCommentsLoader(url: URL) -> () -> AnyPublisher<[ImageComment], Error> {
        return { [httpClient] in
            httpClient
                .loadPublisher(from: url)
                .tryMap(ImageCommentsMapper.map)
                .eraseToAnyPublisher()
        }
    }

    private func makeRemoteFeedLoaderWithLocalFallback() -> AnyPublisher<Paginated<FeedImage>, Error> {
        makeRemoteFeedLoader()
            .caching(to: localFeedLoader)
            .fallback(to: localFeedLoader.loadPublisher)
            .map(makeFirstPage)
            .eraseToAnyPublisher()
    }
    
    private func makeRemoteLoadMoreLoader(lastItem: FeedImage?) -> AnyPublisher<Paginated<FeedImage>, Error> {
        localFeedLoader.loadPublisher()
            .zip(makeRemoteFeedLoader(after: lastItem)) { cachedItems, newItems in
                (cachedItems + newItems, newItems.last)
            }
            .map(self.makePage)
            .caching(to: localFeedLoader)
            .eraseToAnyPublisher()
    }
    
    private func makeRemoteFeedLoader(after lastItem: FeedImage? = nil) -> AnyPublisher<[FeedImage], Error> {
        let url = FeedEndpoint.get(after: lastItem).url(baseURL: baseURL)
        return httpClient
            .loadPublisher(from: url)
            .tryMap(FeedItemsMapper.map)
            .eraseToAnyPublisher()
    }
    
    private func makeFirstPage(items: [FeedImage]) -> Paginated<FeedImage> {
        makePage(items: items, lastItem: items.last)
    }
    
    private func makePage(items: [FeedImage], lastItem: FeedImage?) -> Paginated<FeedImage> {
        return Paginated(
            items: items,
            loadMorePublisher: lastItem.map { lastItem in
                { self.makeRemoteLoadMoreLoader(lastItem: lastItem) }
            }
        )
    }

    private func makeLocalImageLoaderWithRemoteFallback(url: URL) -> FeedImageDataLoader.Publisher {
        return localImageLoader
            .loadPublisher(from: url)
            .fallback(to: { [httpClient, localImageLoader, scheduler] in
                httpClient
                    .loadPublisher(from: url)
                    .tryMap(FeedImageDataMapper.map)
                    .caching(to: localImageLoader, using: url)
                    .subscribe(on: scheduler)
                    .eraseToAnyPublisher()
            })
            .subscribe(on: scheduler)
            .eraseToAnyPublisher()
    }
}
