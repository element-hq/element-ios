/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

/// Protocol describing a router that wraps the root navigation of the application.
/// Routers are used to be passed between coordinators. They handles only `physical` navigation.
protocol RootRouterType: AnyObject {          
    
    /// Update the root view controller
    ///
    /// - Parameter module: The new root view controller to set
    func setRootModule(_ module: Presentable)        
    
    /// Dismiss the root view controller
    ///
    /// - Parameters:
    ///     - animated: Specify true to animate the transition.
    ///     - completion: The closure executed after the view controller is dismissed.
    func dismissRootModule(animated: Bool, completion: (() -> Void)?)
    
    /// Present modally a view controller on the root view controller
    ///
    /// - Parameters:
    ///   - module: Specify true to animate the transition.
    ///   - animated: Specify true to animate the transition.
    ///   - completion: Animation completion.
    func presentModule(_ module: Presentable, animated: Bool, completion: (() -> Void)?)
    
    /// Dismiss modally presented view controller from root view controller
    ///
    /// - Parameters:
    ///   - animated: Specify true to animate the transition.
    ///   - completion: Animation completion.
    func dismissModule(animated: Bool, completion: (() -> Void)?)
}
