//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed

final class FeedImageViewModel<Image> {
    typealias Observer<T> = (T) -> Void

    private var task: FeedImageDataLoaderTask?
    private let model: FeedImage
    private let imageLoader: FeedImageDataLoader
    private var imageDataTransformer: (Data) -> Image?

    var description: String? {
        model.description
    }

    var location: String? {
        model.location
    }

    var hasLocation: Bool {
        model.location != nil
    }

    var onImageLoad: Observer<Image?>?
    var onImageLoadingStateChange: Observer<Bool>?
    var onIsRetryButtonHiddenStateChange: Observer<Bool>?

    init(model: FeedImage, imageLoader: FeedImageDataLoader, imageDataTransformer: @escaping (Data) -> Image?) {
        self.model = model
        self.imageLoader = imageLoader
        self.imageDataTransformer = imageDataTransformer
    }

    func load() {
        onImageLoadingStateChange?(true)
        onIsRetryButtonHiddenStateChange?(true)
        task = self.imageLoader.loadImageData(from: self.model.url) { [weak self] result in
            self?.handle(result)
        }
    }

    private func handle(_ result: Result<Data, Error>) {
        if let image = (try? result.get()).flatMap(imageDataTransformer) {
            onImageLoad?(image)
        } else {
            onIsRetryButtonHiddenStateChange?(false)
        }

        onImageLoadingStateChange?(false)
    }

    func preload() {
        task = imageLoader.loadImageData(from: self.model.url) { _ in }
    }

    func cancelLoad() {
        task?.cancel()
        task = nil
    }
}
