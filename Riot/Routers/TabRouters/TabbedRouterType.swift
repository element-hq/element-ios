// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

struct TabbedRouterTab {
    let title: String?
    let icon: UIImage?
    let module: Presentable
}

/// Protocol describing a router that wraps the root navigation of the application.
/// Routers are used to be passed between coordinators. They handles only `physical` navigation.
protocol TabbedRouterType: AnyObject, Presentable {
    var tabs: [TabbedRouterTab] { get set }
            
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
