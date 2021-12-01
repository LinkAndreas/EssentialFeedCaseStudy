//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol FeedImageView {
    associatedtype Image: Equatable

    func display(_ viewModel: FeedImageViewModel<Image>)
}

public final class FeedImagePresenter<View: FeedImageView, Image> where View.Image == Image {
    private struct InvalidImageDataError: Error {}

    private let view: View
    private var imageDataTransformer: (Data) -> Image?

    public init(view: View, imageDataTransformer: @escaping (Data) -> Image?) {
        self.view = view
        self.imageDataTransformer = imageDataTransformer
    }

    public func didStartLoadingImageData(for model: FeedImage) {
        view.display(
            FeedImageViewModel<Image>(
                description: model.description,
                location: model.location,
                image: nil,
                isLoading: true,
                shouldRetry: false
            )
        )
    }

    public func didFinishLoadingImageData(with data: Data, for model: FeedImage) {
        guard let image = imageDataTransformer(data) else {
            return didFinishLoadingImageData(with: InvalidImageDataError(), for: model)
        }

        view.display(
            FeedImageViewModel<Image>(
                description: model.description,
                location: model.location,
                image: image,
                isLoading: false,
                shouldRetry: false
            )
        )
    }

    public func didFinishLoadingImageData(with error: Error, for model: FeedImage) {
        view.display(
            FeedImageViewModel<Image>(
                description: model.description,
                location: model.location,
                image: nil,
                isLoading: false,
                shouldRetry: true
            )
        )
    }
}


