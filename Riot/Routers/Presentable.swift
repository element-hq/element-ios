/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

/// Protocol used to pass UIViewControllers to routers
protocol Presentable {
    func toPresentable() -> UIViewController
}

extension UIViewController: Presentable {
    public func toPresentable() -> UIViewController {
        return self
    }
}

extension Presentable {
    
    /// Returns a new module from the presentable without a pop completion block
    /// - Returns: Module
    func toModule() -> NavigationModule {
        return NavigationModule(presentable: self, popCompletion: nil)
    }
    
}
