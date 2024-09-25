/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

extension UIViewController {
    
    private enum UIViewControllerConstants {
        static let fabButtonSize = CGSize(width: 78, height: 78)
        static let fabButtonTrailingMargin: CGFloat = 0
        static let fabButtonBottomMargin: CGFloat = 9
    }
    
    /// Remove back bar button title when pushing a view controller.
    /// This method should be called on the previous controller in UINavigationController stack.
    @objc func vc_removeBackTitle() {
        self.navigationItem.backButtonDisplayMode = .minimal
    }

    /// Add a child view controller matching current view controller view.
    ///
    /// - Parameter viewController: The child view controller to add.
    func vc_addChildViewController(viewController: UIViewController) {
        self.vc_addChildViewController(viewController: viewController, onView: self.view)
    }
    
    
    /// Add a child view controller on current view controller.
    ///
    /// - Parameters:
    ///   - viewController: The child view controller to add.
    ///   - view: The view on which to add the child view controller view.
    ///   - animated: true to add a fade in animation
    func vc_addChildViewController(viewController: UIViewController, onView view: UIView, animated: Bool = false) {
        self.addChild(viewController)
        
        viewController.view.frame = view.bounds
        if animated {
            viewController.view.alpha = 0
        }
        view.vc_addSubViewMatchingParent(viewController.view)
        if animated {
            UIView.animate(withDuration: 0.2) {
                viewController.view.alpha = 1
            }
        }
        viewController.didMove(toParent: self)
    }
    
    
    /// Remove a child view controller from current view controller.
    ///
    /// - Parameters:
    ///     - viewController: The child view controller to remove.
    ///     - animated: true to add a fade out animation
    func vc_removeChildViewController(viewController: UIViewController, animated: Bool = false) {
        viewController.willMove(toParent: nil)
        if animated {
            UIView.animate(withDuration: 0.2) {
                viewController.view.alpha = 0
            } completion: { finished in
                viewController.view.removeFromSuperview()
                viewController.view.alpha = 1
            }
        } else {
            viewController.view.removeFromSuperview()
        }
        viewController.removeFromParent()
    }
    
    
    /// Remove current view controller from parent.
    ///
    /// - Parameter animated: true to add a fade out animation
    func vc_removeFromParent(animated: Bool = false) {
        self.vc_removeChildViewController(viewController: self, animated: animated)
    }
    
    /// Adds a floating action button to the bottom-right of the page.
    /// - Parameters:
    ///   - image: Image to be showed in fab
    ///   - target: target of the button
    ///   - action: action of the button
    /// - Returns: The FAB view
    @discardableResult
    @objc func vc_addFAB(withImage image: UIImage,
                         target: Any?,
                         action: Selector?) -> UIImageView {
        
        let fabImageView = UIImageView(image: image)
        fabImageView.translatesAutoresizingMaskIntoConstraints = false
        fabImageView.backgroundColor = .clear
        fabImageView.contentMode = .center
        fabImageView.layer.shadowOpacity = 0.3
        fabImageView.layer.shadowOffset = CGSize(width: 0, height: 3)
        fabImageView.isUserInteractionEnabled = true
        
        self.view.addSubview(fabImageView)
        
        fabImageView.widthAnchor.constraint(equalToConstant: UIViewControllerConstants.fabButtonSize.width).isActive = true
        fabImageView.heightAnchor.constraint(equalToConstant: UIViewControllerConstants.fabButtonSize.height).isActive = true
        fabImageView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                                               constant: UIViewControllerConstants.fabButtonTrailingMargin).isActive = true
        self.view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: fabImageView.bottomAnchor,
                                                              constant: UIViewControllerConstants.fabButtonBottomMargin).isActive = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: target, action: action)
        tapGestureRecognizer.numberOfTouchesRequired = 1
        tapGestureRecognizer.numberOfTapsRequired = 1
        fabImageView.addGestureRecognizer(tapGestureRecognizer)
        
        return fabImageView
    }
    
    /// Defines the large title display mode for the view controller
    /// - Parameters:
    ///   - largeTitleDisplayMode: large title display mode
    @objc func vc_setLargeTitleDisplayMode(_ largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode) {
        switch largeTitleDisplayMode {
        case .automatic:
              guard let navigationController = navigationController else { break }
            if let index = navigationController.children.firstIndex(of: self) {
                vc_setLargeTitleDisplayMode(index == 0 ? .always : .never)
            } else {
                vc_setLargeTitleDisplayMode(.always)
            }
        case .always, .never:
            navigationItem.largeTitleDisplayMode = largeTitleDisplayMode
            // Even when .never, needs to be true otherwise animation will be broken on iOS11, 12, 13
            navigationController?.navigationBar.prefersLargeTitles = true
        @unknown default:
            MXLog.failure("[UIViewController] setLargeTitleDisplayMode: Missing handler", context: largeTitleDisplayMode)
        }
    }

    /// Set leftBarButtonItem with split view display mode button if there is no leftBarButtonItem defined and splitViewController exists.
    /// To be Used when view controller is displayed as detail controller in split view.
    func vc_setupDisplayModeLeftBarButtonItemIfNeeded() {
        guard let splitViewController = self.splitViewController, self.navigationItem.leftBarButtonItem == nil else {
            return
        }
        
        // If there is no leftBarButtonItem defined,
        // set split view display mode button as left bar button item
        self.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
    }

    /// Set the view controller to be displayed in fullscreen modal presentation style on any iOS version.
    ///
    /// - Parameters:
    ///   - isFullScreen: whether view controller should be displayed full screen
    /// - Returns: the view controller
    @discardableResult
    func vc_setModalFullScreen(_ isFullScreen: Bool) -> UIViewController {
        if #available(iOS 13.0, *) {
            self.modalPresentationStyle = isFullScreen ? .fullScreen : .automatic
        }

        return self
    }
}
