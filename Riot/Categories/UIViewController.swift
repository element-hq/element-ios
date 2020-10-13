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

extension UIViewController {
    
    private enum UIViewControllerConstants {
        static let fabButtonSize = CGSize(width: 78, height: 78)
        static let fabButtonTrailingMargin: CGFloat = 0
        static let fabButtonBottomMargin: CGFloat = 9
    }
    
    /// Remove back bar button title when pushing a view controller.
    /// This method should be called on the previous controller in UINavigationController stack.
    @objc func vc_removeBackTitle() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
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
    func vc_addChildViewController(viewController: UIViewController, onView view: UIView) {
        self.addChild(viewController)
        
        viewController.view.frame = view.bounds
        view.vc_addSubViewMatchingParent(viewController.view)
        viewController.didMove(toParent: self)
    }
    
    
    /// Remove a child view controller from current view controller.
    ///
    /// - Parameter viewController: The child view controller to remove.
    func vc_removeChildViewController(viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
    
    
    /// Remove current view controller from parent.
    func vc_removeFromParent() {
        self.vc_removeChildViewController(viewController: self)
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
}
