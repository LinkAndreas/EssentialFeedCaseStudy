//  Copyright © 2021 Andreas Link. All rights reserved.

import Combine
import EssentialFeediOS
import EssentialFeed

class LoadResourcePresentationAdapter<Resource, View: ResourceView> {
    var presenter: LoadResourcePresenter<Resource, View>?

    private let loader: () -> AnyPublisher<Resource, Error>
    private var cancellable: AnyCancellable?

    init(loader: @escaping () -> AnyPublisher<Resource, Error>) {
        self.loader = loader
    }

    func loadResource() {
        presenter?.didStartLoading()
        cancellable = loader().sink(
            receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished: break

                case let .failure(error):
                    self?.presenter?.didStopLoading(with: error)
                }
            },
            receiveValue: { [weak self] resource in
                self?.presenter?.didStopLoading(with: resource)
            }
        )
    }
}

extension LoadResourcePresentationAdapter: FeedViewControllerDelegate {
    func didTriggerRefresh() {
        loadResource()
    }
}

extension LoadResourcePresentationAdapter: FeedImageCellControllerDelegate {
    func didTriggerPreload() {
        loadResource()
    }

    func didCancelLoad() {
        cancellable?.cancel()
        cancellable = nil
    }

    func didRequestImage() {
        loadResource()
    }
}
