/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// `RootRouter` is a concrete implementation of RootRouterType.
final class RootRouter: RootRouterType {
    
    // MARK: - Constants
    
    // `rootViewController` animation constants
    private enum RootViewControllerUpdateAnimation {
        static let duration: TimeInterval = 0.3
        static let options: UIView.AnimationOptions = .transitionCrossDissolve
    }
    
    // MARK: - Properties
    
    private var presentedModule: Presentable?
    
    let window: UIWindow
    
    /// The root view controller currently presented    
    var rootViewController: UIViewController? {
        return self.window.rootViewController
    }
    
    // MARK: - Setup
    
    init(window: UIWindow) {
        self.window = window
    }
    
    // MARK: - Public methods
    
    func setRootModule(_ module: Presentable) {
        self.updateRootViewController(rootViewController: module.toPresentable(), animated: false, completion: nil)
        self.window.makeKeyAndVisible()
    }
    
    func dismissRootModule(animated: Bool, completion: (() -> Void)?) {
        self.updateRootViewController(rootViewController: nil, animated: animated, completion: completion)
    }
    
    func presentModule(_ module: Presentable, animated: Bool, completion: (() -> Void)?) {
        let viewControllerPresenter = self.rootViewController?.presentedViewController ?? self.rootViewController
        
        viewControllerPresenter?.present(module.toPresentable(), animated: animated, completion: completion)
        self.presentedModule = module
    }
    
    func dismissModule(animated: Bool, completion: (() -> Void)?) {
        self.presentedModule?.toPresentable().dismiss(animated: animated, completion: completion)
    }
    
    // MARK: - Private methods
    
    private func updateRootViewController(rootViewController: UIViewController?, animated: Bool, completion: (() -> Void)?) {
        
        if animated {
            UIView.transition(with: window, duration: RootViewControllerUpdateAnimation.duration, options: RootViewControllerUpdateAnimation.options, animations: {
                let oldState: Bool = UIView.areAnimationsEnabled
                UIView.setAnimationsEnabled(false)
                self.window.rootViewController = rootViewController
                UIView.setAnimationsEnabled(oldState)
            }, completion: { (finished: Bool) -> Void in
                completion?()
            })
        } else {
            self.window.rootViewController = rootViewController
            completion?()
        }
    }
}
