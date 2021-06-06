//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

internal final class FeedCachePolicy {
    private static var maxCacheAgeInDays: Int = 7
    private static let calendar: Calendar = .init(identifier: .gregorian)

    private init() {}

    internal static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard
            let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp)
        else { return false }

        return date < maxCacheAge
    }
}
