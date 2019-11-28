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

/// `SlidingModalPresentationController` handles sliding transition presentation life cycle.
final class SlidingModalPresentationController: UIPresentationController {
    
    // MARK: - Properties
    
    private var slidingModalContainerView: SlidingModalContainerView? {
        return self.containerView?.subviews.first(where: { (view) -> Bool in
            view is SlidingModalContainerView
        }) as? SlidingModalContainerView
    }
    
    // MARK: - Setup
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }
    
    // MARK: - Life cycle
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let slidingModalPresentable = self.presentedViewController as? SlidingModalPresentable, let slidingModalContainerView = self.slidingModalContainerView {
            
            let slidingModalContainerViewContentViewWidth = slidingModalContainerView.contentViewWidthFittingSize(size)
            
            let presentableHeight = slidingModalPresentable.layoutHeightFittingWidth(slidingModalContainerViewContentViewWidth)
            slidingModalContainerView.updateContentViewMaxHeight(presentableHeight)
        }
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.slidingModalContainerView?.updateContentViewLayout()
        }, completion: { _ in
            
        })
    }
    
    override func presentationTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            return
        }
        
        coordinator.animate(alongsideTransition: { [weak self] _ in
            // Update status bar appearance of presented view controller (if presenting view controller allowed it, see `modalPresentationCapturesStatusBarAppearance` property)
            self?.presentedViewController.setNeedsStatusBarAppearanceUpdate()
        }, completion: nil)
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        self.slidingModalContainerView?.delegate = self
    }
    
    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            return
        }

        coordinator.animate(alongsideTransition: { [weak self] _ -> Void in
            // Update status bar appearance of presenting view controller
            self?.presentingViewController.setNeedsStatusBarAppearanceUpdate()
        }, completion: nil)
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            self.slidingModalContainerView?.removeFromSuperview()
        }
    }
}

// MARK: - SlidingModalContainerViewDelegate
extension SlidingModalPresentationController: SlidingModalContainerViewDelegate {
    
    func slidingModalContainerViewDidTapBackground(_ view: SlidingModalContainerView) {
        
        let isDismissOnBackgroundTapAllowed: Bool
        
        if let slidingModalPresentable = self.presentedViewController as? SlidingModalPresentable {
            isDismissOnBackgroundTapAllowed = slidingModalPresentable.allowsDismissOnBackgroundTap()
        } else {
            isDismissOnBackgroundTapAllowed = true
        }
        
        if isDismissOnBackgroundTapAllowed {
            self.presentedViewController.dismiss(animated: true, completion: nil)
        }
    }
}
