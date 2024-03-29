//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed

func uniqueImage() -> FeedImage {
    return .init(id: UUID(), description: "any", location: "any", url: anyURL())
}

func uniqueImageFeed() -> (models: [FeedImage], locals: [LocalFeedImage]) {
    let feed: [FeedImage] = [uniqueImage(), uniqueImage()]
    let locals: [LocalFeedImage] = feed.map { image in
        LocalFeedImage(id: image.id, description: image.description, location: image.location, url: image.url)
    }

    return (feed, locals)
}

extension Date {
    func minusFeedCacheMaxAge() -> Self {
        return adding(days: -feedCacheMaxAgeInDays)
    }

    private var feedCacheMaxAgeInDays: Int {
        return 7
    }
}
