//  Copyright © 2022 Andreas Link. All rights reserved.

import UIKit

public struct CellController {
    let id: AnyHashable
    let dataSource: UITableViewDataSource
    let delegate: UITableViewDelegate?
    let dataSourcePrefetching: UITableViewDataSourcePrefetching?

    public init(
        id: AnyHashable = UUID(),
        dataSource: UITableViewDataSource,
        delegate: UITableViewDelegate? = nil,
        dataSourcePrefetching: UITableViewDataSourcePrefetching? = nil
    ) {
        self.id = id
        self.dataSource = dataSource
        self.delegate = delegate
        self.dataSourcePrefetching = dataSourcePrefetching
    }
}

extension CellController: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension CellController: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}
