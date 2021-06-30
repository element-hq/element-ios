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

/// `SlidingModalPresentationAnimator` handles the animations for a custom sliding view controller transition.
final class SlidingModalPresentationAnimator: NSObject {
    
    // MARK: - Constants
    
    private enum AnimationDuration {
        static let presentation: TimeInterval = 0.2
        static let dismissal: TimeInterval = 0.3
    }
    
    // MARK: - Properties

    private let isPresenting: Bool
    private let options: SlidingModalOption
    
    // MARK: - Setup
    
    /// Instantiate a SlidingModalPresentationAnimator object.
    ///
    /// - Parameter isPresenting: true to animate presentation or false to animate dismissal
    /// - Parameter isSpanning: true to remove left, bottom and right spaces between the screen edges and the content view
    required public init(isPresenting: Bool, options: SlidingModalOption) {
        self.isPresenting = isPresenting
        self.options = options
        super.init()
    }
    
    // MARK: - Private
    
    // Animate presented view controller presentation
    private func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedViewController = transitionContext.viewController(forKey: .to),
            transitionContext.viewController(forKey: .from) != nil else {
                return
        }
        
        guard let presentedViewControllerView = presentedViewController.view else {
            return
        }
        
        let containerView = transitionContext.containerView
        
        // Spanning not available for iPad
        let slidingModalContainerView = options.contains(.spanning) && UIDevice.current.userInterfaceIdiom != .pad ? SpanningSlidingModalContainerView.instantiate() : SlidingModalContainerView.instantiate()
        slidingModalContainerView.blurBackground = options.contains(.blurBackground)
        slidingModalContainerView.centerInScreen = options.contains(.centerInScreen)
        slidingModalContainerView.alpha = 0
        slidingModalContainerView.updateDimmingViewAlpha(0.0)
        
        // Add presented view controller view to slidingModalContainerView content view
        slidingModalContainerView.setContentView(presentedViewControllerView)
        
        // Add slidingModalContainerView to container view
        containerView.vc_addSubViewMatchingParent(slidingModalContainerView)
        containerView.layoutIfNeeded()
        
        // Adapt slidingModalContainerView content view height from presentedViewControllerView height 
        if let slidingModalPresentable = presentedViewController as? SlidingModalPresentable {
            let slidingModalContainerViewContentViewWidth = slidingModalContainerView.contentViewFrame.width
            let presentableHeight = slidingModalPresentable.layoutHeightFittingWidth(slidingModalContainerViewContentViewWidth)
            slidingModalContainerView.updateContentViewMaxHeight(presentableHeight)
            slidingModalContainerView.updateContentViewLayout()
        }
        
        // Hide slidingModalContainerView content view
        slidingModalContainerView.prepareDismissAnimation()
        containerView.layoutIfNeeded()
        
        let animationDuration = self.transitionDuration(using: transitionContext)
        
        slidingModalContainerView.preparePresentAnimation()
        slidingModalContainerView.alpha = 1
        
        UIView.animate(withDuration: animationDuration, animations: {
            containerView.layoutIfNeeded()
            slidingModalContainerView.updateDimmingViewAlpha(1.0)
        }, completion: { completed in
            transitionContext.completeTransition(completed)
        })
    }
    
    // Animate presented view controller dismissal
    private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        
        let containerView = transitionContext.containerView
        
        let slidingModalContainerView = self.slidingModalContainerView(from: transitionContext)
        
        let animationDuration = self.transitionDuration(using: transitionContext)
        
        slidingModalContainerView?.prepareDismissAnimation()
        
        UIView.animate(withDuration: animationDuration, animations: {
            containerView.layoutIfNeeded()
            slidingModalContainerView?.updateDimmingViewAlpha(0.0)
        }, completion: { completed in
            transitionContext.completeTransition(completed)
        })
    }
    
    private func slidingModalContainerView(from transitionContext: UIViewControllerContextTransitioning) -> SlidingModalContainerView? {
        let modalContentView = transitionContext.containerView.subviews.first(where: { view -> Bool in
            view is SlidingModalContainerView
        }) as? SlidingModalContainerView
        return modalContentView
    }
}

// MARK: - UIViewControllerAnimatedTransitioning
extension SlidingModalPresentationAnimator: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.isPresenting ? AnimationDuration.presentation : AnimationDuration.dismissal
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if self.isPresenting {
            self.animatePresentation(using: transitionContext)
        } else {
            self.animateDismissal(using: transitionContext)
        }
    }
}
