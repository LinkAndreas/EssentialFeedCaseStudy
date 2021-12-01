//
//  FeedLoaderWithFallbackComposite.swift
//  EssentialApp
//
//  Created by Andreas Link on 01.12.21.
//

import EssentialFeed

public final class FeedLoaderWithFallbackComposite: FeedLoader {
    private let primary: FeedLoader
    private let fallback: FeedLoader

    public init(primary: FeedLoader, fallback: FeedLoader) {
        self.primary = primary
        self.fallback = fallback
    }

    public func fetchFeed(completion: @escaping (FeedLoader.Result) -> Void) {
        primary.fetchFeed { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                completion(result)

            case .failure:
                self.fallback.fetchFeed(completion: completion)
            }
        }
    }
}
