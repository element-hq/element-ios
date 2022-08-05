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
import WeakDictionary

/// `NavigationRouter` is a concrete implementation of NavigationRouterType.
final class NavigationRouter: NSObject, NavigationRouterType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var completions: [UIViewController : () -> Void]
    private let navigationController: UINavigationController
    
    /// Stores the association between the added Presentable and his view controller.
    /// They can be the same if the controller is not added via his Coordinator or it is a simple UIViewController.
    private var storedModules = WeakDictionary<UIViewController, AnyObject>()
    
    // MARK: Public
    
    /// Returns the presentables associated to each view controller
    var modules: [Presentable] {
        return self.viewControllers.map { (viewController) -> Presentable in
            return self.module(for: viewController)
        }
    }
    
    /// Return the view controllers stack
    var viewControllers: [UIViewController] {
        return navigationController.viewControllers
    }
    
    // MARK: - Setup
    
    init(navigationController: UINavigationController = RiotNavigationController()) {
        self.navigationController = navigationController
        self.completions = [:]
        super.init()
        self.navigationController.delegate = self
        self.navigationController.overrideUserInterfaceStyle = ThemeService.shared().theme.userInterfaceStyle

        // Post local notification on NavigationRouter creation
        let userInfo: [String: Any] = [NavigationRouter.NotificationUserInfoKey.navigationRouter: self,
                        NavigationRouter.NotificationUserInfoKey.navigationController: navigationController]
        NotificationCenter.default.post(name: NavigationRouter.didCreate, object: self, userInfo: userInfo)
        NotificationCenter.default.addObserver(self, selector: #selector(self.themeDidChange), name: Notification.Name.themeServiceDidChangeTheme, object: nil)
    }
    
    deinit {
        // Post local notification on NavigationRouter deinit
        let userInfo: [String: Any] = [NavigationRouter.NotificationUserInfoKey.navigationRouter: self,
                        NavigationRouter.NotificationUserInfoKey.navigationController: navigationController]
        NotificationCenter.default.post(name: NavigationRouter.willDestroy, object: self, userInfo: userInfo)
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
            MXLog.error("Cannot add a UINavigationController to NavigationRouter")
            return
        }
        
        self.addModule(module, for: controller)
        
        let controllersToPop = self.navigationController.viewControllers.reversed()
        
        controllersToPop.forEach {
            self.willPopViewController($0)
        }
        
        if let popCompletion = popCompletion {
            completions[controller] = popCompletion
        }
        
        self.willPushViewController(controller)
        
        navigationController.setViewControllers([controller], animated: animated)
        navigationController.isNavigationBarHidden = hideNavigationBar
        
        // Pop old view controllers
        controllersToPop.forEach {
            self.didPopViewController($0)
        }
        
        // Add again controller to module association, in case same module instance is added back
        self.addModule(module, for: controller)
        
        self.didPushViewController(controller)
    }
        
    func setModules(_ modules: [NavigationModule], hideNavigationBar: Bool, animated: Bool) {
        
        MXLog.debug("[NavigationRouter] Set modules \(modules)")
        
        let controllers = modules.map { (module) -> UIViewController in
            let controller = module.presentable.toPresentable()
            self.addModule(module.presentable, for: controller)
            return controller
        }
                
        let controllersToPop = self.navigationController.viewControllers.reversed()
        
        controllersToPop.forEach {
            self.willPopViewController($0)
        }
        
        controllers.forEach {
            self.willPushViewController($0)
        }
        
        // Set new view controllers
        navigationController.setViewControllers(controllers, animated: animated)
        navigationController.isNavigationBarHidden = hideNavigationBar
        
        // Pop old view controllers
        controllersToPop.forEach {
            self.didPopViewController($0)
        }
        
        // Add again controller to module association, in case same modules instance are added back
        modules.forEach { (module) in
            self.addModule(module.presentable, for: module.presentable.toPresentable())
        }
        
        controllers.forEach {
            self.didPushViewController($0)
        }
    }
    
    func popToRootModule(animated: Bool) {
        MXLog.debug("[NavigationRouter] Pop to root module")
        
        let controllers = self.navigationController.viewControllers
        
        if controllers.count > 1 {
            let controllersToPop = controllers[1..<controllers.count]
            
            controllersToPop.reversed().forEach {
                self.willPopViewController($0)
            }
        }
        
        if let controllers = navigationController.popToRootViewController(animated: animated) {
            controllers.reversed().forEach {
                self.didPopViewController($0)
            }
        }
    }
    
    func popToModule(_ module: Presentable, animated: Bool) {
        MXLog.debug("[NavigationRouter] Pop to module \(module)")
        
        let controller = module.toPresentable()
        let controllersBeforePop = self.navigationController.viewControllers
        
        if let controllerIndex = controllersBeforePop.firstIndex(of: controller) {
            let controllersToPop = controllersBeforePop[controllerIndex..<controllersBeforePop.count]
            
            controllersToPop.reversed().forEach {
                self.willPopViewController($0)
            }
        }
        
        if let controllers = navigationController.popToViewController(controller, animated: animated) {
            controllers.reversed().forEach {
                self.didPopViewController($0)
            }
        }
    }
    
    func push(_ module: Presentable, animated: Bool = true, popCompletion: (() -> Void)? = nil) {
        MXLog.debug("[NavigationRouter] Push module \(module)")
        
        let controller = module.toPresentable()
        
        // Avoid pushing UINavigationController onto stack
        guard controller is UINavigationController == false else {
            MXLog.error("Cannot push a UINavigationController to NavigationRouter")
            return
        }
        
        self.addModule(module, for: controller)
        
        if let completion = popCompletion {
            completions[controller] = completion
        }
        
        self.willPushViewController(controller)
        
        navigationController.pushViewController(controller, animated: animated)
        
        self.didPushViewController(controller)
    }
    
    func push(_ modules: [NavigationModule], animated: Bool) {
        MXLog.debug("[NavigationRouter] Push modules \(modules)")
        
        // Avoid pushing any UINavigationController onto stack
        guard modules.first(where: { $0.presentable.toPresentable() is UINavigationController }) == nil else {
            MXLog.error("Cannot push a UINavigationController to NavigationRouter")
            return
        }
        
        for module in modules {
            let controller = module.presentable.toPresentable()
            self.addModule(module.presentable, for: controller)
            
            if let completion = module.popCompletion {
                completions[controller] = completion
            }
            
            self.willPushViewController(controller)
        }
        
        var viewControllers = navigationController.viewControllers
        viewControllers.append(contentsOf: modules.map({ $0.presentable.toPresentable() }))
        navigationController.setViewControllers(viewControllers, animated: animated)
        
        for module in modules {
            let controller = module.presentable.toPresentable()
            self.didPushViewController(controller)
        }
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
        
        let controllersToPop = self.navigationController.viewControllers.reversed()
        
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
    
    // MARK: - Theme management
    
    @objc private func themeDidChange() {
        self.navigationController.overrideUserInterfaceStyle = ThemeService.shared().theme.userInterfaceStyle
    }
    
    // MARK: - Private
    
    private func module(for viewController: UIViewController) -> Presentable {
        
        guard let module = self.storedModules[viewController] as? Presentable else {
            return viewController
        }
        return module
    }
    
    private func addModule(_ module: Presentable, for viewController: UIViewController) {
        self.storedModules[viewController] = module as AnyObject
    }
    
    private func removeModule(for viewController: UIViewController) {
        self.storedModules[viewController] = nil
    }
    
    private func runCompletion(for controller: UIViewController) {
        guard let completion = completions[controller] else {
            return
        }
        completion()
        completions.removeValue(forKey: controller)
    }
    
    private func willPushViewController(_ viewController: UIViewController) {
        self.postNotification(withName: NavigationRouter.willPushModule, for: viewController)
    }
    
    private func didPushViewController(_ viewController: UIViewController) {
        self.postNotification(withName: NavigationRouter.didPushModule, for: viewController)
    }
    
    private func willPopViewController(_ viewController: UIViewController) {
        self.postNotification(withName: NavigationRouter.willPopModule, for: viewController)
    }
    
    private func didPopViewController(_ viewController: UIViewController) {                
        self.postNotification(withName: NavigationRouter.didPopModule, for: viewController)
        
        // Call completion closure associated to the view controller
        // So associated coordinator can be deallocated
        runCompletion(for: viewController)
        
        self.removeModule(for: viewController)
    }
    
    private func postNotification(withName name: Notification.Name, for viewController: UIViewController) {
        
        let module = self.module(for: viewController)
        
        let userInfo: [String: Any] = [
            NotificationUserInfoKey.navigationRouter: self,
            NotificationUserInfoKey.module: module,
            NotificationUserInfoKey.viewController: viewController
        ]
        NotificationCenter.default.post(name: name, object: self, userInfo: userInfo)
    }
}

// MARK: - UINavigationControllerDelegate
extension NavigationRouter: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        // TODO: Try to post `NavigationRouter.willPopModule` notification here
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
        // Ensure the view controller is popping
        guard let poppedViewController = navigationController.transitionCoordinator?.viewController(forKey: .from),
            !navigationController.viewControllers.contains(poppedViewController) else {
                return
        }
        
        MXLog.debug("[NavigationRouter] Popped module: \(poppedViewController)")
        
        self.didPopViewController(poppedViewController)
    }
}

// MARK: - NavigationRouter notification constants
extension NavigationRouter {
    
    // MARK: Notification names
    
    public static let willPushModule = Notification.Name("NavigationRouterWillPushModule")
    public static let didPushModule = Notification.Name("NavigationRouterDidPushModule")
    public static let willPopModule = Notification.Name("NavigationRouterWillPopModule")
    public static let didPopModule = Notification.Name("NavigationRouterDidPopModule")
    
    public static let didCreate = Notification.Name("NavigationRouterDidCreate")
    public static let willDestroy = Notification.Name("NavigationRouterWillDestroy")
    
    // MARK: Notification keys
    
    public struct NotificationUserInfoKey {
        
        /// The associated view controller (UIViewController).
        static let viewController = "viewController"
        
        /// The associated module (Presentable), can the view controller itself or is Coordinator
        static let module = "module"
        
        /// The navigation router that send the notification (NavigationRouterType)
        static let navigationRouter = "navigationRouter"
        
        /// The navigation controller (UINavigationController) associated to the navigation router
        static let navigationController = "navigationController"
    }
}
