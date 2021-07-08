//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

func anyURL() -> URL {
    return URL(string: "http://any.url")!
}

func anyNSError() -> NSError {
    return .init(domain: "any domain", code: 42, userInfo: nil)
}
