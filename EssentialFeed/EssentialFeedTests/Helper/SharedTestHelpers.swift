//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

func anyData() -> Data {
    return "Any data".data(using: .utf8)!
}

func anyURL() -> URL {
    return URL(string: "http://any.url")!
}

func anyNSError() -> NSError {
    return .init(domain: "any domain", code: 42, userInfo: nil)
}

func makeJSONData(items: [[String: Any]]) -> Data {
    let json: [String: Any] = ["items": items]
    return try! JSONSerialization.data(withJSONObject: json)
}

extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}

extension Date {
    func adding(seconds: Int, calendar: Calendar = Calendar(identifier: .gregorian)) -> Self {
        calendar.date(byAdding: .second, value: seconds, to: self)!
    }

    func adding(minutes: Int, calendar: Calendar = Calendar(identifier: .gregorian)) -> Self {
        calendar.date(byAdding: .minute, value: minutes, to: self)!
    }

    func adding(days: Int, calendar: Calendar = Calendar(identifier: .gregorian)) -> Self {
        calendar.date(byAdding: .day, value: days, to: self)!
    }
}
