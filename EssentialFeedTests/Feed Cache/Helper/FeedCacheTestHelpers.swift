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
        return adding(days: -7)
    }

    func adding(seconds: Int) -> Self {
        let calendar: Calendar = .init(identifier: .gregorian)
        return calendar.date(byAdding: .second, value: seconds, to: self)!
    }

    func adding(days: Int) -> Self {
        let calendar: Calendar = .init(identifier: .gregorian)
        return calendar.date(byAdding: .day, value: days, to: self)!
    }
}
