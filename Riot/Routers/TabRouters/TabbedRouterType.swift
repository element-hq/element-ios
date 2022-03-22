// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
