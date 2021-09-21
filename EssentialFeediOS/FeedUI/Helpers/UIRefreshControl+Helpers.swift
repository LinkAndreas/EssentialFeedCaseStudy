//  Copyright © 2021 Andreas Link. All rights reserved.

import UIKit

 extension UIRefreshControl {
     func update(isRefreshing: Bool) {
         isRefreshing ? beginRefreshing() : endRefreshing()
     }
 }
