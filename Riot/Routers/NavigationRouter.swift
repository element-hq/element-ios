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

/// `NavigationRouter` is a concrete implementation of NavigationRouterType.
final class NavigationRouter: NSObject, NavigationRouterType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var completions: [UIViewController : () -> Void]
    private let navigationController: UINavigationController
    
    // MARK: Public
    
    var modules: [Presentable] {
        return navigationController.viewControllers
    }
    
    // MARK: - Setup
    
    init(navigationController: UINavigationController = RiotNavigationController()) {
        self.navigationController = navigationController
        self.completions = [:]
        super.init()
        self.navigationController.delegate = self
    }
    
    // MARK: - Public
    
    func present(_ module: Presentable, animated: Bool = true) {
        MXLog.debug("[NavigationRouter] Present \(module)")
        navigationController.present(module.toPresentable(), animated: animated, completion: nil)
    }
    
    func dismissModule(animated: Bool = true, completion: (() -> Void)? = nil) {
        MXLog.debug("[NavigationRouter] Dismiss presented module")
        navigationController.dismiss(animated: animated, completion: completion)
    }
    
    func setRootModule(_ module: Presentable, hideNavigationBar: Bool = false, animated: Bool = false, popCompletion: (() -> Void)? = nil) {
        MXLog.debug("[NavigationRouter] Set root module \(module)")
        
        let controller = module.toPresentable()
        
        // Avoid setting a UINavigationController onto stack
        guard controller is UINavigationController == false else {
            return
        }
        
        // Call all completions so all coordinators can be deallocated
        for presentable in completions.keys {
            runCompletion(for: presentable)
        }
        
        if let popCompletion = popCompletion {
            completions[controller] = popCompletion
        }
        
        navigationController.setViewControllers([controller], animated: animated)
        navigationController.isNavigationBarHidden = hideNavigationBar
    }
    
    func popToRootModule(animated: Bool) {
        MXLog.debug("[NavigationRouter] Pop to root module")
        
        if let controllers = navigationController.popToRootViewController(animated: animated) {
            controllers.forEach { runCompletion(for: $0) }
        }
    }
    
    func popToModule(_ module: Presentable, animated: Bool) {
        MXLog.debug("[NavigationRouter] Pop to module \(module)")
        
        if let controllers = navigationController.popToViewController(module.toPresentable(), animated: animated) {
            controllers.forEach { runCompletion(for: $0) }
        }
    }
    
    func push(_ module: Presentable, animated: Bool = true, popCompletion: (() -> Void)? = nil) {
        MXLog.debug("[NavigationRouter] Push module \(module)")
        
        let controller = module.toPresentable()
        
        // Avoid pushing UINavigationController onto stack
        guard controller is UINavigationController == false else {
            return
        }
        
        if let completion = popCompletion {
            completions[controller] = completion
        }
        
        navigationController.pushViewController(controller, animated: animated)        
    }
    
    func popModule(animated: Bool = true) {
        MXLog.debug("[NavigationRouter] Pop module")
        
        if let controller = navigationController.popViewController(animated: animated) {
            runCompletion(for: controller)
        }
    }
        
    // MARK: Presentable
    
    func toPresentable() -> UIViewController {
        return navigationController
    }
    
    // MARK: - Private
    
    private func runCompletion(for controller: UIViewController) {
        guard let completion = completions[controller] else {
            return
        }
        completion()
        completions.removeValue(forKey: controller)
    }
}

// MARK: - UINavigationControllerDelegate
extension NavigationRouter: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
        // Ensure the view controller is popping
        guard let poppedViewController = navigationController.transitionCoordinator?.viewController(forKey: .from),
            !navigationController.viewControllers.contains(poppedViewController) else {
                return
        }
        
        MXLog.debug("[NavigationRouter] Poppped module: \(poppedViewController)")
        
        runCompletion(for: poppedViewController)
    }
}
