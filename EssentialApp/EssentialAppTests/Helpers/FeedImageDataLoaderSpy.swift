//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed

final class FeedImageDataLoaderSpy: FeedImageDataLoader {
    private final class Task: FeedImageDataLoaderTask {
        private let callback: () -> Void

        init(callback: @escaping () -> Void) {
            self.callback = callback
        }

        func cancel() {
            callback()
        }
    }

    private (set) var receivedMessages: [(url: URL, completion: ((LoadResult) -> Void))] = []
    var loadedURLs: [URL] { receivedMessages.map(\.url) }
    var cancelledURLs: [URL] = []
    private var completions: [(LoadResult) -> Void] { receivedMessages.map(\.completion) }

    func loadImageData(from url: URL, completion: @escaping (LoadResult) -> Void) -> FeedImageDataLoaderTask {
        receivedMessages.append((url, completion))
        return Task { [weak self] in
            self?.cancelledURLs.append(url)
        }
    }

    func complete(with data: Data, atIndex index: Int = 0) {
        completions[index](.success(data))
    }

    func complete(with error: Error, atIndex index: Int = 0) {
        completions[index](.failure(error))
    }
}
