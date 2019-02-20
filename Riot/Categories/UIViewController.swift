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
    
    /// Remove back bar button title when pushing a view controller.
    /// This method should be called on the previous controller in UINavigationController stack.
    func vc_removeBackTitle() {
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
}
