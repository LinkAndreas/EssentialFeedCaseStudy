//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import EssentialFeediOS
import Combine

final class FeedImageDataLoaderPresentationAdapter<View: FeedImageView, Image>: FeedImageCellControllerDelegate where View.Image == Image {
    var presenter: FeedImagePresenter<View, Image>?

    private let model: FeedImage
    private let imageLoader: (URL) -> FeedImageDataLoader.Publisher
    private var cancellable: AnyCancellable?

    init(model: FeedImage, imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher) {
        self.model = model
        self.imageLoader = imageLoader
    }

    func didRequestImage() {
        presenter?.didStartLoadingImageData(for: model)
        cancellable = imageLoader(model.url).sink(
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }

                switch completion {
                case .finished:
                    break

                case let .failure(error):
                    self.presenter?.didFinishLoadingImageData(with: error, for: self.model)
                }
            },
            receiveValue: { [weak self] imageData in
                guard let self = self else { return }

                self.presenter?.didFinishLoadingImageData(with: imageData, for: self.model)
            }
        )
    }

    func didTriggerPreload() {
        cancellable = imageLoader(model.url).sink(receiveCompletion: { _ in }, receiveValue: {_ in })
    }

    func didCancelLoad() {
        cancellable?.cancel()
        cancellable = nil
    }
}
