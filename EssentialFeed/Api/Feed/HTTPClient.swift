//  Copyright © 2021 Andreas Link. All rights reserved.

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>

    func load(from url: URL, completion: @escaping (Result) -> Void)
}
