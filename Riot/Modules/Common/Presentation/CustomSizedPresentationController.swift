// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/// Controller for custom sized presentations.
/// By default, presented view controller will be sized as both half of the screen in width and height, and will be centered to the screen.
/// Implement `CustomSizedPresentable` in presented view controller to change that if needed.
/// This class can also be set as `transitioningDelegate` as presented view controller, as it's conforming `UIViewControllerTransitioningDelegate`.
@objcMembers
class CustomSizedPresentationController: UIPresentationController {
    
    //  MARK: - Public Properties
    
    /// Corner radius for presented view controller's view. Default value is `8.0`.
    var cornerRadius: CGFloat = 8.0
    
    /// Background color of dimming view, which is located behind the presented view controller's view. Default value is `white with 0.5 alpha`.
    var dimColor: UIColor = UIColor(white: 0.0, alpha: 0.5)
    
    /// Dismiss view controller when background tapped. Default value is `true`.
    var dismissOnBackgroundTap: Bool = true
    
    //  MARK: - Private Properties
    
    /// Dim view
    private var dimmingView: UIView!
    
    /// Wrapper view for presentation. It's introduced to handle corner radius on presented view controller's view and it's superview of all other views.
    private var presentationWrappingView: UIView!
    
    //  MARK: - Initializer
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        presentedViewController.modalPresentationStyle = .custom
    }
    
    //  MARK: - Actions
    
    @objc private func dimmingViewTapped(_ sender: UITapGestureRecognizer) {
        if dismissOnBackgroundTap {
            presentedViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    //  MARK: - Presentation
    
    override func presentationTransitionWillBegin() {
        guard let presentedViewControllerView = super.presentedView else { return }
        
        // Wrap the presented view controller's view in an intermediate hierarchy
        // that applies a shadow and rounded corners to the top-left and top-right
        // edges.  The final effect is built using three intermediate views.
        //
        // presentationWrapperView              <- shadow
        //   |- presentationRoundedCornerView   <- rounded corners (masksToBounds)
        //        |- presentedViewControllerWrapperView
        //             |- presentedViewControllerView (presentedViewController.view)
        //
        // SEE ALSO: The note in AAPLCustomPresentationSecondViewController.m.
        do {
            let presentationWrapperView = UIView(frame: frameOfPresentedViewInContainerView)
            presentationWrapperView.layer.shadowOffset = CGSize(width: 0, height: -2)
            presentationWrapperView.layer.shadowRadius = 10
            presentationWrapperView.layer.shadowColor = UIColor(white: 0, alpha: 0.5).cgColor
            presentationWrappingView = presentationWrapperView
            
            // presentationRoundedCornerView is CORNER_RADIUS points taller than the
            // height of the presented view controller's view.  This is because
            // the cornerRadius is applied to all corners of the view.  Since the
            // effect calls for only the top two corners to be rounded we size
            // the view such that the bottom CORNER_RADIUS points lie below
            // the bottom edge of the screen.
            let cornerViewRect = presentationWrapperView.bounds// .inset(by: UIEdgeInsets(top: 0, left: 0, bottom: -cornerRadius, right: 0))
            
            let presentationRoundedCornerView = UIView(frame: cornerViewRect)
            presentationRoundedCornerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            presentationRoundedCornerView.layer.cornerRadius = cornerRadius
            presentationRoundedCornerView.layer.masksToBounds = true
            
            // To undo the extra height added to presentationRoundedCornerView,
            // presentedViewControllerWrapperView is inset by CORNER_RADIUS points.
            // This also matches the size of presentedViewControllerWrapperView's
            // bounds to the size of -frameOfPresentedViewInContainerView.
            let wrapperRect = presentationRoundedCornerView.bounds
            
            let presentedViewControllerWrapperView = UIView(frame: wrapperRect)
            presentedViewControllerWrapperView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            // Add presentedViewControllerView -> presentedViewControllerWrapperView.
            presentedViewControllerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            presentedViewControllerView.frame = presentedViewControllerWrapperView.bounds
            presentedViewControllerWrapperView.addSubview(presentedViewControllerView)
            
            // Add presentedViewControllerWrapperView -> presentationRoundedCornerView.
            presentationRoundedCornerView.addSubview(presentedViewControllerWrapperView)
            
            // Add presentationRoundedCornerView -> presentationWrapperView.
            presentationWrapperView.addSubview(presentationRoundedCornerView)
        }
        
        // Add a dimming view behind presentationWrapperView.  self.presentedView
        // is added later (by the animator) so any views added here will be
        // appear behind the -presentedView.
        do {
            let dimmingView = UIView(frame: containerView?.bounds ?? .zero)
            dimmingView.backgroundColor = dimColor
            dimmingView.isOpaque = false
            dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped(_:)))
            dimmingView.addGestureRecognizer(tapGestureRecognizer)
            
            self.dimmingView = dimmingView
            containerView?.addSubview(dimmingView)
            
            // Get the transition coordinator for the presentation so we can
            // fade in the dimmingView alongside the presentation animation.
            let transitionCoordinator = self.presentingViewController.transitionCoordinator
            
            dimmingView.alpha = 0.0
            transitionCoordinator?.animate(alongsideTransition: { _ in
                self.dimmingView?.alpha = 1.0
            }, completion: nil)
        }
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        if !completed {
            presentationWrappingView = nil
            dimmingView = nil
        }
    }
    
    //  MARK: - Dismissal
    
    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentingViewController.transitionCoordinator else {
            dimmingView.alpha = 0.0
            return
        }
        
        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.0
        })
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            presentationWrappingView = nil
            dimmingView = nil
        }
    }
    
    //  MARK: - Overrides
    
    override var presentedView: UIView? {
        return presentationWrappingView
    }
    
    override func size(forChildContentContainer container: UIContentContainer,
                       withParentContainerSize parentSize: CGSize) -> CGSize {
        guard container === presentedViewController else {
            return super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
        }
        
        //  return value from presentable if implemented
        if let presentable = presentedViewController as? CustomSizedPresentable,
           let customSize = presentable.customSize?(withParentContainerSize: parentSize) {
            return customSize
        }
        if let navController = presentedViewController as? UINavigationController,
           let presentable = navController.viewControllers.first(where: { $0 is CustomSizedPresentable }) as? CustomSizedPresentable,
           let customSize = presentable.customSize?(withParentContainerSize: parentSize) {
            return customSize
        }
        
        //  half of the width/height by default
        return CGSize(width: parentSize.width/2.0, height: parentSize.height/2.0)
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else {
            return super.frameOfPresentedViewInContainerView
        }
        
        let size = self.size(forChildContentContainer: presentedViewController,
                             withParentContainerSize: containerView.bounds.size)
        
        //  use origin value from presentable if implemented
        if let presentable = presentedViewController as? CustomSizedPresentable,
           let origin = presentable.position?(withParentContainerSize: containerView.bounds.size) {
            return CGRect(origin: origin, size: size)
        }
        if let navController = presentedViewController as? UINavigationController,
           let presentable = navController.viewControllers.first(where: { $0 is CustomSizedPresentable }) as? CustomSizedPresentable,
           let origin = presentable.position?(withParentContainerSize: containerView.bounds.size) {
            return CGRect(origin: origin, size: size)
        }
        
        //  center presented view by default
        let origin = CGPoint(x: (containerView.bounds.width - size.width)/2,
                             y: (containerView.bounds.height - size.height)/2)
        
        return CGRect(origin: origin, size: size)
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        
        self.dimmingView?.frame = containerView?.bounds ?? .zero
        self.presentationWrappingView?.frame = frameOfPresentedViewInContainerView
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        
        if container === presentedViewController {
            self.containerView?.setNeedsLayout()
        }
    }
    
}

//  MARK: - UIViewControllerTransitioningDelegate

extension CustomSizedPresentationController: UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let controller = CustomSizedPresentationController(presentedViewController: presented, presenting: presenting)
        controller.cornerRadius = cornerRadius
        controller.dimColor = dimColor
        controller.dismissOnBackgroundTap = dismissOnBackgroundTap
        return controller
    }
    
}
