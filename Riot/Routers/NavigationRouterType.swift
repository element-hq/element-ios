/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit

/// Protocol describing a router that wraps a UINavigationController and add convenient completion handlers. Completions are called when a Presentable is removed.
/// Routers are used to be passed between coordinators. They handles only `physical` navigation.
protocol NavigationRouterType: AnyObject, Presentable {

    /// Present modally a view controller on the navigation controller
    ///
    /// - Parameter module: The Presentable to present.
    /// - Parameter animated: Specify true to animate the transition.
    func present(_ module: Presentable, animated: Bool)
    
    /// Dismiss presented view controller from navigation controller
    ///
    /// - Parameter animated: Specify true to animate the transition.
    /// - Parameter completion: Animation completion (not the pop completion).
    func dismissModule(animated: Bool, completion: (() -> Void)?)
    
    /// Set root view controller of navigation controller
    ///
    /// - Parameter module: The Presentable to set as root.
    /// - Parameter hideNavigationBar: Specify true to hide the UINavigationBar.
    /// - Parameter animated: Specify true to animate the transition.
    /// - Parameter popCompletion: Completion called when `module` is removed from the navigation stack.
    func setRootModule(_ module: Presentable, hideNavigationBar: Bool, animated: Bool, popCompletion: (() -> Void)?)
    
    /// Set view controllers stack of navigation controller
    /// - Parameters:
    ///   - modules: The modules stack to set.
    ///   - hideNavigationBar: Specify true to hide the UINavigationBar.
    ///   - animated: Specify true to animate the transition.
    func setModules(_ modules: [NavigationModule], hideNavigationBar: Bool, animated: Bool)
    
    /// Pop to root view controller of navigation controller and remove all others
    ///
    /// - Parameter animated: Specify true to animate the transition.
    func popToRootModule(animated: Bool)
    
    /// Pops view controllers until the specified view controller is at the top of the navigation stack
    ///
    /// - Parameter module: The Presentable that should to be at the top of the stack.
    /// - Parameter animated: Specify true to animate the transition.
    func popToModule(_ module: Presentable, animated: Bool)
    
    /// Push a view controller on navigation controller stack
    ///
    /// - Parameter animated: Specify true to animate the transition.
    /// - Parameter popCompletion: Completion called when `module` is removed from the navigation stack.
    func push(_ module: Presentable, animated: Bool, popCompletion: (() -> Void)?)
    
    /// Push some view controllers on navigation controller stack
    ///
    /// - Parameter modules: Modules to push
    /// - Parameter animated: Specify true to animate the transition.
    func push(_ modules: [NavigationModule], animated: Bool)
    
    /// Pop last view controller from navigation controller stack
    ///
    /// - Parameter animated: Specify true to animate the transition.
    func popModule(animated: Bool)
    
    /// Pops all view controllers
    ///
    /// - Parameter animated: Specify true to animate the transition.
    func popAllModules(animated: Bool)
    
    /// Returns the modules that are currently in the navigation stack
    var modules: [Presentable] { get }
    
    /// Check if the navigation controller contains the given presentable.
    /// - Parameter module: The presentable for which to check the existence.
    func contains(_ module: Presentable) -> Bool
}

// `NavigationRouterType` default implementation
extension NavigationRouterType {
    
    func setRootModule(_ module: Presentable) {
        setRootModule(module, hideNavigationBar: false, animated: false, popCompletion: nil)
    }
    
    func setRootModule(_ module: Presentable, popCompletion: (() -> Void)?) {
        setRootModule(module, hideNavigationBar: false, animated: false, popCompletion: popCompletion)
    }
    
    func setModules(_ modules: [NavigationModule], animated: Bool) {
        setModules(modules, hideNavigationBar: false, animated: animated)
    }
    
    func setModules(_ modules: [Presentable], animated: Bool) {
        setModules(modules, hideNavigationBar: false, animated: animated)
    }
    
}

//  MARK: - Presentable <--> NavigationModule Transitive Methods

extension NavigationRouterType {
    
    func setRootModule(_ module: NavigationModule) {
        setRootModule(module.presentable, popCompletion: module.popCompletion)
    }
    
    func push(_ module: NavigationModule, animated: Bool) {
        push(module.presentable, animated: animated, popCompletion: module.popCompletion)
    }
    
    func setModules(_ modules: [Presentable], hideNavigationBar: Bool, animated: Bool) {
        setModules(modules.map { $0.toModule() },
                   hideNavigationBar: hideNavigationBar,
                   animated: animated)
    }
    
    func push(_ modules: [Presentable], animated: Bool) {
        push(modules.map { $0.toModule() },
             animated: animated)
    }
    
}
