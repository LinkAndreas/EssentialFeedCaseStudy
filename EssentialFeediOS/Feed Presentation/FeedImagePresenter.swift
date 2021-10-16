//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation
import EssentialFeed

protocol FeedImageView {
    associatedtype Image

    func display(_ viewModel: FeedImageViewModel<Image>)
}

final class FeedImagePresenter<View: FeedImageView, Image> where View.Image == Image {
    private struct InvalidImageDataError: Error {}

    private let view: View
    private var imageDataTransformer: (Data) -> Image?

    init(view: View, imageDataTransformer: @escaping (Data) -> Image?) {
        self.view = view
        self.imageDataTransformer = imageDataTransformer
    }

    func didStartLoadingImageData(for model: FeedImage) {
        view.display(
            FeedImageViewModel(
                description: model.description,
                location: model.location,
                image: nil,
                isLoading: true,
                shouldRetry: false
            )
        )
    }

    func didFinishLoadingImageData(with data: Data, for model: FeedImage) {
        guard let image = imageDataTransformer(data) else {
            return didFinishLoadingImageData(with: InvalidImageDataError(), for: model)
        }

        view.display(
            FeedImageViewModel(
                description: model.description,
                location: model.location,
                image: image,
                isLoading: false,
                shouldRetry: false
            )
        )
    }

    func didFinishLoadingImageData(with error: Error, for model: FeedImage) {
        view.display(
            FeedImageViewModel(
                description: model.description,
                location: model.location,
                image: nil,
                isLoading: false,
                shouldRetry: true
            )
        )
    }
}


