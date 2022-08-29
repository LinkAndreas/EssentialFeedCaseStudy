//  Copyright © 2021 Andreas Link. All rights reserved.

import Combine
import EssentialFeed

public extension Paginated {
    init(items: [Item], loadMorePublisher: (() -> AnyPublisher<Self, Error>)?) {
        self.init(items: items, loadMore: loadMorePublisher.map { publisher in
            return { loadMoreCompletion in
                publisher().subscribe(
                    Subscribers.Sink(
                        receiveCompletion: { completion in
                            if case let .failure(error) = completion {
                                loadMoreCompletion(.failure(error))
                            }
                        },
                        receiveValue: { value in
                            loadMoreCompletion(.success(value))
                        }
                    )
                )
            }
        })
    }

    var loadMorePublisher: AnyPublisher<Self, Error>? {
        guard let loadMore = loadMore else { return nil }

        return Deferred {
            Future(loadMore)
        }
        .eraseToAnyPublisher()
    }
}

public extension HTTPClient {
    typealias Publisher = AnyPublisher<(Data, HTTPURLResponse), Error>

    func loadPublisher(from url: URL) -> Publisher {
        var task: HTTPClientTask?
        return Deferred {
            Future { completion in
                task = self.load(from: url, completion: completion)
            }
        }
        .handleEvents(receiveCancel: { task?.cancel() })
        .eraseToAnyPublisher()
    }
}

public extension FeedImageDataLoader {
    typealias Publisher = AnyPublisher<Data, Error>

    func loadPublisher(from url: URL) -> Publisher {
        Deferred {
            Future { completion in
                completion(Result { try self.loadImageData(from: url) })
            }
        }
        .eraseToAnyPublisher()
    }
}

public extension LocalFeedLoader {
    typealias Publisher = AnyPublisher<[FeedImage], Error>

    func loadPublisher() -> Publisher {
        Deferred {
            Future(self.load)
        }
        .eraseToAnyPublisher()
    }
}

private extension FeedCache {
    func saveIgnoringResult(_ feed: [FeedImage]) {
        save(feed) { _ in }
    }
    
    func saveIgnoringResult(_ feed: Paginated<FeedImage>) {
        saveIgnoringResult(feed.items)
    }
}

private extension FeedImageDataCache {
    func saveIgnoringResult(_ data: Data, for url: URL) {
        try? save(data, for: url)
    }
}

extension Publisher {
    func caching(to cache: FeedCache) -> AnyPublisher<Output, Failure> where Output == [FeedImage] {
        return handleEvents(receiveOutput: cache.saveIgnoringResult)
            .eraseToAnyPublisher()
    }
    
    func caching(to cache: FeedCache) -> AnyPublisher<Output, Failure> where Output == Paginated<FeedImage> {
        return handleEvents(receiveOutput: cache.saveIgnoringResult)
            .eraseToAnyPublisher()
    }
}

extension Publisher where Output == Data {
    func caching(to cache: FeedImageDataCache, using url: URL) -> AnyPublisher<Output, Failure> {
        return handleEvents(receiveOutput: { cache.saveIgnoringResult($0, for: url) })
            .eraseToAnyPublisher()
    }
}

extension Publisher {
    func fallback(to fallbackPublisher:  @escaping () -> AnyPublisher<Output, Failure>) -> AnyPublisher<Output, Failure> {
        self.catch { _ in fallbackPublisher() }.eraseToAnyPublisher()
    }
}

extension Publisher {
    func dispatchOnMainQueue() -> AnyPublisher<Output, Failure> {
        return receive(on: DispatchQueue.immediateWhenOnMainQueueScheduler).eraseToAnyPublisher()
    }
}

extension DispatchQueue {
    static var immediateWhenOnMainQueueScheduler: ImmediateWhenOnMainQueueScheduler { .init() }

    struct ImmediateWhenOnMainQueueScheduler: Scheduler {
        typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
        typealias SchedulerOptions = DispatchQueue.SchedulerOptions

        var now: DispatchQueue.SchedulerTimeType {
            return DispatchQueue.main.now
        }

        var minimumTolerance: DispatchQueue.SchedulerTimeType.Stride {
            return DispatchQueue.main.minimumTolerance
        }

        func schedule(options: DispatchQueue.SchedulerOptions?, _ action: @escaping () -> Void) {
            guard Thread.isMainThread else {
                return DispatchQueue.main.schedule(options: options, action)
            }

            action()
        }

        func schedule(
            after date: DispatchQueue.SchedulerTimeType,
            tolerance: DispatchQueue.SchedulerTimeType.Stride,
            options: DispatchQueue.SchedulerOptions?,
            _ action: @escaping () -> Void
        ) {
            DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: options, action)
        }

        func schedule(
            after date: DispatchQueue.SchedulerTimeType,
            interval: DispatchQueue.SchedulerTimeType.Stride,
            tolerance: DispatchQueue.SchedulerTimeType.Stride,
            options: DispatchQueue.SchedulerOptions?,
            _ action: @escaping () -> Void
        ) -> Cancellable {
            return DispatchQueue.main.schedule(
                after: date,
                interval: interval,
                tolerance: tolerance,
                options: options,
                action
            )
        }
    }
}

typealias AnyDispatchQueueScheduler = AnyScheduler<DispatchQueue.SchedulerTimeType, DispatchQueue.SchedulerOptions>

extension Scheduler {
    func eraseToAnyScheduler() -> AnyScheduler<SchedulerTimeType, SchedulerOptions> {
        AnyScheduler(self)
    }
}

final class AnyScheduler<SchedulerTimeType: Strideable, SchedulerOptions>: Scheduler where SchedulerTimeType.Stride: SchedulerTimeIntervalConvertible {
    private var _now: (() -> SchedulerTimeType)!
    private var _minimumTolerance: (() -> SchedulerTimeType.Stride)!
    private var _schedule: ((SchedulerOptions?, @escaping () -> Void) -> Void)!
    private var _scheduleAfter: ((SchedulerTimeType, SchedulerTimeType.Stride, SchedulerOptions?, @escaping () -> Void) -> Void)!
    private var _scheduleAfterInterval: ((SchedulerTimeType, SchedulerTimeType.Stride, SchedulerTimeType.Stride, SchedulerOptions?, @escaping () -> Void) -> Cancellable)!

    init<S: Scheduler>(_ scheduler: S) where S.SchedulerTimeType == SchedulerTimeType, S.SchedulerOptions == SchedulerOptions {
        _now = { scheduler.now }
        _minimumTolerance = { scheduler.minimumTolerance }
        _schedule = { scheduler.schedule(options: $0, $1)}
        _scheduleAfter = { scheduler.schedule(after: $0, tolerance: $1, options: $2, $3)}
        _scheduleAfterInterval = { scheduler.schedule(after: $0, interval: $1, tolerance: $2, options: $3, $4)}
    }

    var now: SchedulerTimeType {
        _now()
    }

    var minimumTolerance: SchedulerTimeType.Stride {
        _minimumTolerance()
    }

    func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
        _schedule(options, action)
    }

    func schedule(
        after date: SchedulerTimeType,
        tolerance: SchedulerTimeType.Stride,
        options: SchedulerOptions?,
        _ action: @escaping () -> Void
    ) {
        _scheduleAfter(date, tolerance, options, action)
    }

    func schedule(
        after date: SchedulerTimeType,
        interval: SchedulerTimeType.Stride,
        tolerance: SchedulerTimeType.Stride,
        options: SchedulerOptions?,
        _ action: @escaping () -> Void
    ) -> Cancellable {
        _scheduleAfterInterval(date, interval, tolerance, options, action)
    }
}
