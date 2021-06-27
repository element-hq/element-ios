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

/// Availbale options for present method
struct SlidingModalOption: OptionSet {
    let rawValue: UInt32

    /// Is content view spanning the screen width and to the bottom
    static let spanning         = SlidingModalOption(rawValue: 1 << 0)
    /// the background is blurred in order to obfuscate the view behind the popup
    static let blurBackground   = SlidingModalOption(rawValue: 1 << 1)
    /// center content in screen
    static let centerInScreen   = SlidingModalOption(rawValue: 1 << 2)
}

/// `SlidingModalPresenter` allows to present a custom UIViewController or UIView conforming to `SlidingModalPresentable` as a modal with a vertical sliding animation from a UIViewController.
final class SlidingModalPresenter: NSObject {
    
    // MARK: - Constants
    
    private enum TabletContentSize {
        static let preferred = CGSize(width: 400.0, height: 400.0)
        static let minHeight: CGFloat = 0.0
        static let maxHeight: CGFloat = 600.0
    }
    
    // MARK: - Properties

    // swiftlint:disable weak_delegate
    private var transitionDelegate: SlidingModalPresentationDelegate?
    // swiftlint:enable weak_delegate
    private weak var presentingViewController: UIViewController?
    
    // MARK: - Presentation options

    @objc static let NoOption: UInt32 = 0
    @objc static let SpanningOption: UInt32 = SlidingModalOption.spanning.rawValue
    @objc static let BlurBackgroungOption: UInt32 = SlidingModalOption.blurBackground.rawValue
    @objc static let CenterInScreenOption: UInt32 = SlidingModalOption.centerInScreen.rawValue

    // MARK: - Public
    
    @objc func present(_ viewController: SlidingModalPresentable.ViewControllerType, from presentingViewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        self.present(viewController, from: presentingViewController, animated: animated, options: [], completion: completion)
    }
    
    @objc func present(_ viewController: SlidingModalPresentable.ViewControllerType, from presentingViewController: UIViewController, animated: Bool, options: UInt32, completion: (() -> Void)?) {
        self.present(viewController, from: presentingViewController, animated: animated, options: SlidingModalOption(rawValue: options), completion: completion)
    }
    
    func present(_ viewController: SlidingModalPresentable.ViewControllerType, from presentingViewController: UIViewController, animated: Bool, options: SlidingModalOption, completion: (() -> Void)?) {
        
        MXLog.debug("[SlidingModalPresenter] present \(type(of: viewController))")
        
        let transitionDelegate = SlidingModalPresentationDelegate(options: options)
        
        viewController.modalPresentationStyle = .custom
        viewController.transitioningDelegate = transitionDelegate
        
        // Presented view controller does not affect the statusbar appearance
        viewController.modalPresentationCapturesStatusBarAppearance = false
        
        self.transitionDelegate = transitionDelegate
        
        presentingViewController.present(viewController, animated: animated, completion: completion)
        
        self.presentingViewController = presentingViewController
    }
    
    @objc func presentView(_ view: SlidingModalPresentable.ViewType, from viewControllerPresenter: UIViewController, animated: Bool, completion: (() -> Void)?) {
        
        MXLog.debug("[SlidingModalPresenter] presentView \(type(of: view))")
        
        let viewController = SlidingModalEmptyViewController.instantiate(with: view)
        self.present(viewController, from: viewControllerPresenter, animated: animated, completion: completion)
    }
    
    @objc func presentView(_ view: SlidingModalPresentable.ViewType, from viewControllerPresenter: UIViewController, animated: Bool, options: UInt32, completion: (() -> Void)?) {
        
        MXLog.debug("[SlidingModalPresenter] presentView \(type(of: view))")
        
        let viewController = SlidingModalEmptyViewController.instantiate(with: view)
        self.present(viewController, from: viewControllerPresenter, animated: animated, options: SlidingModalOption(rawValue: options), completion: completion)
    }
    
    @objc func dismiss(animated: Bool, completion: (() -> Void)?) {
        self.presentingViewController?.dismiss(animated: animated, completion: completion)
    }
}
