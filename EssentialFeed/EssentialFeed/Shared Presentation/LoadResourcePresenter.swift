//  Copyright © 2022 Andreas Link. All rights reserved.

import Foundation

public protocol ResourceView {
    associatedtype ResourceViewModel

    func display(_ viewModel: ResourceViewModel)
}

public final class LoadResourcePresenter<Resource, View: ResourceView> {
    public typealias Mapper = (Resource) throws -> View.ResourceViewModel

    private let resourceView: View
    private let loadingView: ResourceLoadingView
    private let errorView: ResourceErrorView
    private let mapper: Mapper

    public static var loadError: String {
        return NSLocalizedString(
            "GENERIC_CONNECTION_ERROR",
            tableName: "Shared",
            bundle: Bundle(for: Self.self),
            comment: "Error message displayed when we can't fetch the resource due to a connection error."
        )
    }

    public init(
        resourceView: View,
        loadingView: ResourceLoadingView,
        errorView: ResourceErrorView,
        mapper: @escaping Mapper
    ) {
        self.resourceView = resourceView
        self.loadingView = loadingView
        self.errorView = errorView
        self.mapper = mapper
    }

    public func didStartLoading() {
        errorView.display(.noError)
        loadingView.display(ResourceLoadingViewModel(isLoading: true))
    }

    public func didStopLoading(with resource: Resource) {
        do {
            resourceView.display(try mapper(resource))
            loadingView.display(ResourceLoadingViewModel(isLoading: false))
        } catch {
            didStopLoading(with: error)
        }
    }

    public func didStopLoading(with error: Error) {
        errorView.display(.error(message: Self.loadError))
        loadingView.display(ResourceLoadingViewModel(isLoading: false))
    }
}
