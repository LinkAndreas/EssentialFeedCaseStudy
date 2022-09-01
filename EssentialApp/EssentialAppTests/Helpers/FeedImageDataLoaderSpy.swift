//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed

final class FeedImageDataLoaderSpy: FeedImageDataLoader {
    private (set) var receivedMessages: [URL] = []
    var loadedURLs: [URL] { receivedMessages }
    var loadResult: Result<Data, Error>!

    func loadImageData(from url: URL) throws -> Data {
        receivedMessages.append(url)
        return try loadResult.get()
    }

    func stubImageLoadResult(with data: Data) {
        loadResult = .success(data)
    }

    func stubImageLoadResult(with error: Error) {
        loadResult = .failure(error)
    }
}
