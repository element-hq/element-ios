/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
