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

import Foundation
import WeakDictionary

/// `NavigationRouterStore` enables to get a NavigationRouter from a UINavigationController instance.
class NavigationRouterStore: NavigationRouterStoreProtocol {
    
    // MARK: - Constants
    
    static let shared = NavigationRouterStore()
    
    // MARK: - Properties

    // FIXME: WeakDictionary does not work with protocol
    // Find a way to use NavigationRouterType as value
    private var navigationRouters = WeakDictionary<UINavigationController, NavigationRouter>()
    
    // MARK: - Setup
    
    /// As we are ensuring that there is only one navigation controller per NavigationRouter, the class here should be used as a singleton.
    private init() {
        self.registerNavigationRouterNotifications()
    }
    
    // MARK: - Public
    
    func navigationRouter(for navigationController: UINavigationController) -> NavigationRouterType {
        
        if let existingNavigationRouter = self.findNavigationRouter(for: navigationController) {
            return existingNavigationRouter
        }
        
        let navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        return navigationRouter
    }
    
    // MARK: - Private
    
    private func findNavigationRouter(for navigationController: UINavigationController) -> NavigationRouterType? {
        return self.navigationRouters[navigationController]
    }
    
    private func removeNavigationRouter(for navigationController: UINavigationController) {
        self.navigationRouters[navigationController] = nil
    }
    
    private func registerNavigationRouterNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(navigationRouterDidCreate(_:)), name: NavigationRouter.didCreate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(navigationRouterWillDestroy(_:)), name: NavigationRouter.willDestroy, object: nil)
    }
    
    @objc private func navigationRouterDidCreate(_ notification: Notification) {
                
        guard let userInfo = notification.userInfo,
              let navigationRouter = userInfo[NavigationRouter.NotificationUserInfoKey.navigationRouter] as? NavigationRouterType,
              let navigationController = userInfo[NavigationRouter.NotificationUserInfoKey.navigationController] as? UINavigationController else {
            return
        }
        
        if let existingNavigationRouter = self.findNavigationRouter(for: navigationController) {
            fatalError("\(existingNavigationRouter) is already tied to the same navigation controller as \(navigationRouter). We should have only one NavigationRouter per navigation controller")
        } else {
            // FIXME: WeakDictionary does not work with protocol
            // Find a way to avoid this cast
            self.navigationRouters[navigationController] = navigationRouter as? NavigationRouter
        }
    }
    
    @objc private func navigationRouterWillDestroy(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let navigationRouter = userInfo[NavigationRouter.NotificationUserInfoKey.navigationRouter] as? NavigationRouterType,
              let navigationController = userInfo[NavigationRouter.NotificationUserInfoKey.navigationController] as? UINavigationController else {
            return
        }
        
        if let existingNavigationRouter = self.findNavigationRouter(for: navigationController), existingNavigationRouter !== navigationRouter {
            fatalError("\(existingNavigationRouter) is already tied to the same navigation controller as \(navigationRouter). We should have only one NavigationRouter per navigation controller")
        }
        
        self.removeNavigationRouter(for: navigationController)
    }
}
