//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed

func anyData() -> Data {
    return "Any data".data(using: .utf8)!
}

func anyURL() -> URL {
    return URL(string: "http://any.url")!
}

func anyNSError() -> NSError {
    return .init(domain: "any domain", code: 42, userInfo: nil)
}

func uniqueFeed() -> [FeedImage] {
    return [FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())]
}

var feedTitle: String {
    FeedPresenter.title
}

var commentsTitle: String {
    ImageCommentsPresenter.title
}

var loadError: String {
    LoadResourcePresenter<Any, DummyView>.loadError
}

class DummyView: ResourceView {
    func display(_ viewModel: Any) {}
}

