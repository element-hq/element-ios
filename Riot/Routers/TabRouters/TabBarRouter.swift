// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import WeakDictionary

class TabBarRouter: NSObject, TabbedRouterType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let tabBarController: UITabBarController
    
    /// Stores the association between the added Presentable and his view controller.
    /// They can be the same if the controller is not added via his Coordinator or it is a simple UIViewController.
    private var storedModules = WeakDictionary<UIViewController, AnyObject>()

    // MARK: Public
    
    /// Returns the presentables associated to each view controller
    var tabs: [TabbedRouterTab] = [] {
        didSet {
            guard !tabs.isEmpty else {
                tabBarController.viewControllers = nil
                return
            }
            
            tabBarController.viewControllers = tabs.compactMap({ tab in
                let viewController = tab.module.toPresentable()
                
                guard viewController is UITabBarController == false else {
                    return nil
                }
                
                if tab.title != nil || tab.icon != nil {
                    viewController.tabBarItem.title = tab.title
                    viewController.tabBarItem.image = tab.icon
                }
                
                return viewController
            })
        }
    }
    
    /// Return the view controllers stack
    var viewControllers: [UIViewController] {
        return tabBarController.viewControllers ?? []
    }
    
    // MARK: - Setup
    
    init(tabBarController: UITabBarController = UITabBarController(), tabs: [TabbedRouterTab]? = nil) {
        self.tabBarController = tabBarController
        super.init()
        self.tabBarController.delegate = self
        
        if let tabs = tabs {
            self.tabs = tabs
        }
    }
        
    // MARK: - Public
    
    func presentModule(_ module: Presentable, animated: Bool, completion: (() -> Void)?) {
        MXLog.debug("[TabBarRouter] Present \(module)")
        tabBarController.present(module.toPresentable(), animated: animated, completion: nil)
    }
    
    func dismissModule(animated: Bool, completion: (() -> Void)?) {
        tabBarController.dismiss(animated: animated, completion: completion)
    }
    
    // MARK: Presentable
    
    func toPresentable() -> UIViewController {
        return tabBarController
    }
    
    // MARK: - Private
    
    private func module(for viewController: UIViewController) -> Presentable {
        
        guard let module = self.storedModules[viewController] as? Presentable else {
            return viewController
        }
        return module
    }
    
}

extension TabBarRouter: UITabBarControllerDelegate {
    
}
