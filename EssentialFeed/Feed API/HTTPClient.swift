//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol HTTPClientTask {
    func cancel()
}

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>

    // The comletion can be called in any Thread. Clients are responsible to dispatch in appropriate threads if needed.
    func load(from url: URL, completion: @escaping (Result) -> Void) -> HTTPClientTask
}
