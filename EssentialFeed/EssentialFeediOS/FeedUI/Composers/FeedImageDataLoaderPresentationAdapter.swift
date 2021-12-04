//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed

final class FeedImageDataLoaderPresentationAdapter<View: FeedImageView, Image>: FeedImageCellControllerDelegate where View.Image == Image {
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
