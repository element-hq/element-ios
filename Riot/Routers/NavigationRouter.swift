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
        
        let controllersToPop = self.navigationController.viewControllers
        
        controllersToPop.forEach {
            self.willPopViewController($0)
        }
        
        if let popCompletion = popCompletion {
            completions[controller] = popCompletion
        }
        
        self.willPushViewController(controller)
        
        navigationController.setViewControllers([controller], animated: animated)
        navigationController.isNavigationBarHidden = hideNavigationBar
        
        self.didPushViewController(controller)
        
        // Pop old view controllers
        controllersToPop.forEach {
            self.didPopViewController($0)
        }
    }
        
    func setModules(_ modules: [Presentable], hideNavigationBar: Bool, animated: Bool) {
        
        MXLog.debug("[NavigationRouter] Set modules \(modules)")
        
        let controllers = modules.map { (presentable) -> UIViewController in
            return presentable.toPresentable()
        }
                
        let controllersToPop = self.navigationController.viewControllers
        
        controllersToPop.forEach {
            self.willPopViewController($0)
        }
        
        controllers.forEach {
            self.willPushViewController($0)
        }
        
        // Set new view controllers
        navigationController.setViewControllers(controllers, animated: animated)
        navigationController.isNavigationBarHidden = hideNavigationBar
        
        controllers.forEach {
            self.didPushViewController($0)
        }
         
        // Pop old view controllers
        controllersToPop.forEach {
            self.didPopViewController($0)
        }
    }
    
    func popToRootModule(animated: Bool) {
        MXLog.debug("[NavigationRouter] Pop to root module")
        
        let controllers = self.navigationController.viewControllers
        
        if controllers.count > 1 {
            let controllersToPop = controllers[1...controllers.count-1]
            
            controllersToPop.forEach {
                self.willPopViewController($0)
            }
        }
        
        if let controllers = navigationController.popToRootViewController(animated: animated) {
            controllers.forEach {
                self.didPopViewController($0)
            }
        }
    }
    
    func popToModule(_ module: Presentable, animated: Bool) {
        MXLog.debug("[NavigationRouter] Pop to module \(module)")
        
        let controller = module.toPresentable()
        let controllersBeforePop = self.navigationController.viewControllers
        
        if let controllerIndex = controllersBeforePop.firstIndex(of: controller) {
            let controllersToPop = controllersBeforePop[controllerIndex...controllersBeforePop.count-1]
            
            controllersToPop.forEach {
                self.willPopViewController($0)
            }
        }
        
        if let controllers = navigationController.popToViewController(module.toPresentable(), animated: animated) {
            controllers.forEach {
                self.didPopViewController($0)
            }
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
        
        self.willPushViewController(controller)
        
        navigationController.pushViewController(controller, animated: animated)
        
        self.didPushViewController(controller)
    }
    
    func popModule(animated: Bool = true) {
        MXLog.debug("[NavigationRouter] Pop module")
        
        if let lastController = navigationController.viewControllers.last {
            self.willPopViewController(lastController)
        }
        
        if let controller = navigationController.popViewController(animated: animated) {
            self.didPopViewController(controller)
        }
    }
    
    func popAllModules(animated: Bool) {
        MXLog.debug("[NavigationRouter] Pop all modules")
        
        let controllersToPop = self.navigationController.viewControllers
        
        controllersToPop.forEach {
            self.willPopViewController($0)
        }        
        
        navigationController.setViewControllers([], animated: animated)
        
        controllersToPop.forEach {
            self.didPopViewController($0)
        }
    }
    
    func contains(_ module: Presentable) -> Bool {
        
        let controller = module.toPresentable()
        return self.navigationController.viewControllers.contains(controller)
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
    
    fileprivate func willPushViewController(_ viewController: UIViewController) {
        self.postNotification(withName: NavigationRouter.willPushViewController, for: viewController)
    }
    
    fileprivate func didPushViewController(_ viewController: UIViewController) {
        self.postNotification(withName: NavigationRouter.didPushViewController, for: viewController)
    }
    
    fileprivate func willPopViewController(_ viewController: UIViewController) {
        self.postNotification(withName: NavigationRouter.willPopViewController, for: viewController)
    }
    
    fileprivate func didPopViewController(_ viewController: UIViewController) {
        
        // Call completion closure associated to the view controller
        // So associated coordinator can be deallocated
        runCompletion(for: viewController)
        
        self.postNotification(withName: NavigationRouter.didPopViewController, for: viewController)
    }
    
    private func postNotification(withName name: Notification.Name, for viewController: UIViewController) {
        let userInfo: [String: Any] = [
            NotificationUserInfoKey.navigationRouter: self,
            NotificationUserInfoKey.viewController: viewController
        ]
        NotificationCenter.default.post(name: name, object: self, userInfo: userInfo)
    }
}

// MARK: - UINavigationControllerDelegate
extension NavigationRouter: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        // TODO: Try to post `NavigationRouter.willPopViewController` notification here
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
        // Ensure the view controller is popping
        guard let poppedViewController = navigationController.transitionCoordinator?.viewController(forKey: .from),
            !navigationController.viewControllers.contains(poppedViewController) else {
                return
        }
        
        MXLog.debug("[NavigationRouter] Poppped module: \(poppedViewController)")
        
        self.didPopViewController(poppedViewController)
    }
}

// MARK: - NavigationRouter notification constants
extension NavigationRouter {
    
    // MARK: Notification names
    
    public static let willPushViewController = Notification.Name("NavigationRouterWillPushViewController")
    public static let didPushViewController = Notification.Name("NavigationRouterDidPushViewController")
    public static let willPopViewController = Notification.Name("NavigationRouterWillPopViewController")
    public static let didPopViewController = Notification.Name("NavigationRouterDidPopViewController")
    
    // MARK: Notification keys
    
    public struct NotificationUserInfoKey {
        static let viewController = "viewController"
        static let navigationRouter = "navigationRouter"
    }
}
