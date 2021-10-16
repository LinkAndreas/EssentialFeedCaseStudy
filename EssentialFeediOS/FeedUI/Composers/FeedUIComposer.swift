//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import UIKit

public enum FeedUIComposer {
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let presentationAdapter = FeedLoaderPresentationAdapter(
            feedLoader: MainQueueDispatchDecorator(decoratee: feedLoader)
        )

        let feedController = FeedViewController.makeWith(delegate: presentationAdapter, title: FeedPresenter.title)
        presentationAdapter.presenter = FeedPresenter(
            feedView: FeedViewAdapter(
                controller: feedController,
                imageLoader: MainQueueDispatchDecorator(decoratee: imageLoader)
            ),
            loadingView: WeakRef(feedController),
            errorView: WeakRef(feedController)
        )
        return feedController
    }
}

private extension FeedViewController {
    static func makeWith(delegate: FeedViewControllerDelegate, title: String) -> FeedViewController {
        let bundle = Bundle(for: FeedViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! FeedViewController
        controller.delegate = delegate
        controller.title = title
        return controller
    }
}

public final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private let imageLoader: FeedImageDataLoader

    init(controller: FeedViewController, imageLoader: FeedImageDataLoader) {
        self.controller = controller
        self.imageLoader = imageLoader
    }

    public func display(_ viewModel: FeedViewModel) {
        controller?.tableModel = viewModel.feed.map { image in
            let adapter = FeedImageDataLoaderPresentationAdapter<WeakRef<FeedImageCellController>, UIImage>(
                model: image,
                imageLoader: imageLoader
            )
            let view = FeedImageCellController(delegate: adapter)
            adapter.presenter = FeedImagePresenter(view: WeakRef(view), imageDataTransformer: UIImage.init)
            return view
        }
    }
}

private final class FeedImageDataLoaderPresentationAdapter<View: FeedImageView, Image>: FeedImageCellControllerDelegate where View.Image == Image {
    var presenter: FeedImagePresenter<View, Image>?

    private let model: FeedImage
    private let imageLoader: FeedImageDataLoader
    private var task: FeedImageDataLoaderTask?

    init(model: FeedImage, imageLoader: FeedImageDataLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }

    func didRequestImage() {
        presenter?.didStartLoadingImageData(for: model)
        task = self.imageLoader.loadImageData(from: self.model.url) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .success(imageData):
                self.presenter?.didFinishLoadingImageData(with: imageData, for: self.model)

            case let .failure(error):
                self.presenter?.didFinishLoadingImageData(with: error, for: self.model)
            }
        }
    }

    func didTriggerPreload() {
        task = imageLoader.loadImageData(from: self.model.url) { _ in }
    }

    func didCancelLoad() {
        task?.cancel()
        task = nil
    }
}

final class FeedLoaderPresentationAdapter: FeedViewControllerDelegate {
    var presenter: FeedPresenter?

    private let feedLoader: FeedLoader

    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    func didTriggerRefresh() {
        presenter?.didStartLoadingFeed()
        feedLoader.fetchFeed { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .success(feed):
                self.presenter?.didStopLoadingFeed(with: feed)

            case let .failure(error):
                self.presenter?.didStopLoadingFeed(with: error)
            }
        }
    }
}

struct WeakRef<T: AnyObject> {
    private weak var object: T?

    init(_ object: T?) {
        self.object = object
    }
}

extension WeakRef: FeedLoadingView where T: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        object?.display(viewModel)
    }
}

extension WeakRef: FeedErrorView where T: FeedErrorView {
    func display(_ viewModel: FeedErrorViewModel) {
        object?.display(viewModel)
    }
}

extension WeakRef: FeedImageView where T: FeedImageView, T.Image == UIImage {
    func display(_ model: FeedImageViewModel<UIImage>) {
        object?.display(model)
    }
}
