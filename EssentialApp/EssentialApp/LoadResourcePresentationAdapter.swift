//  Copyright © 2021 Andreas Link. All rights reserved.

import Combine
import EssentialFeediOS
import EssentialFeed

class LoadResourcePresentationAdapter<Resource, View: ResourceView> {
    var presenter: LoadResourcePresenter<Resource, View>?

    private let loader: () -> AnyPublisher<Resource, Error>
    private var isLoading: Bool = false
    private var cancellable: AnyCancellable?

    init(loader: @escaping () -> AnyPublisher<Resource, Error>) {
        self.loader = loader
    }

    func loadResource() {
        guard !isLoading else { return }

        isLoading = true
        presenter?.didStartLoading()
        cancellable = loader()
            .dispatchOnMainQueue()
            .handleEvents(receiveCancel: { [weak self] in
                self?.isLoading = false
            })
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished: break

                    case let .failure(error):
                        self?.presenter?.didStopLoading(with: error)
                    }

                    self?.isLoading = false
                },
                receiveValue: { [weak self] resource in
                    self?.presenter?.didStopLoading(with: resource)
                }
            )
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
