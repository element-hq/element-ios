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

import Foundation

/// `SlidingModalPresentationDelegate` handle a custom sliding UIViewController transition.
class SlidingModalPresentationDelegate: NSObject {
    private let options: SlidingModalOption
    
    init(options: SlidingModalOption) {
        self.options = options
        super.init()
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension SlidingModalPresentationDelegate: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlidingModalPresentationAnimator(isPresenting: true, options: options)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlidingModalPresentationAnimator(isPresenting: false, options: options)
    }
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let controller = SlidingModalPresentationController(presentedViewController: presented, presenting: presenting)
        controller.delegate = self
        return controller
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension SlidingModalPresentationDelegate: UIAdaptivePresentationControllerDelegate {

    // Do not adapt to size classes
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
