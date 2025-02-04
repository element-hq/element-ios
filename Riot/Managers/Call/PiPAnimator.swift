// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objc enum PiPAnimationType: Int {
    case enter
    case exit
}

@objcMembers
class PiPAnimator: NSObject {
    
    private enum Constants {
        static let pipViewSize: CGSize = CGSize(width: 90, height: 130)
    }

    let animationDuration: TimeInterval
    let animationType: PiPAnimationType
    weak var pipViewDelegate: PiPViewDelegate?
    
    init(animationDuration: TimeInterval,
         animationType: PiPAnimationType,
         pipViewDelegate: PiPViewDelegate?) {
        self.animationDuration = animationDuration
        self.animationType = animationType
        self.pipViewDelegate = pipViewDelegate
        super.init()
    }
    
    private func enterAnimation(context: UIViewControllerContextTransitioning) {
        guard let keyWindow = UIApplication.shared.keyWindow else {
            context.completeTransition(false)
            return
        }
        
        guard let fromVC = context.viewController(forKey: .from) else {
            context.completeTransition(false)
            return
        }
        
        if let pipable = fromVC as? PictureInPicturable {
            pipable.willEnterPiP?()
        }
        
        fromVC.willMove(toParent: nil)
        //  TODO: find a way to call this at the end of animation
        context.completeTransition(true)
        fromVC.removeFromParent()
        
        let pipView = PiPView(frame: fromVC.view.bounds)
        pipView.contentView = fromVC.view
        pipView.delegate = pipViewDelegate
        keyWindow.addSubview(pipView)
        
        let scale = Constants.pipViewSize.width/pipView.frame.width
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let targetSize = Constants.pipViewSize
        pipView.cornerRadius = pipView.cornerRadius / scale
        
        let animator = UIViewPropertyAnimator(duration: animationDuration, dampingRatio: 1) {
            pipView.transform = transform
            
            pipView.move(in: keyWindow,
                         targetSize: targetSize)
        }
        
        animator.addCompletion { (position) in
            if let pipable = fromVC as? PictureInPicturable {
                pipable.didEnterPiP?()
            }
            fromVC.dismiss(animated: false, completion: nil)
        }

        animator.startAnimation()
    }
    
    private func exitAnimation(context: UIViewControllerContextTransitioning) {
        guard let keyWindow = UIApplication.shared.keyWindow else {
            context.completeTransition(false)
            return
        }
        
        guard let toVC = context.viewController(forKey: .to) else {
            context.completeTransition(false)
            return
        }
        
        if let pipable = toVC as? PictureInPicturable {
            pipable.willExitPiP?()
        }
        
        guard let snapshot = toVC.view.snapshotView(afterScreenUpdates: true) else {
            context.completeTransition(false)
            return
        }
        
        guard let pipView = toVC.view.superview as? PiPView else {
            return
        }
        
        context.containerView.addSubview(toVC.view)
        context.containerView.addSubview(snapshot)
        toVC.view.isHidden = true
        
        toVC.additionalSafeAreaInsets = keyWindow.safeAreaInsets
        
        pipView.contentView = nil
        pipView.removeFromSuperview()
        
        snapshot.frame = pipView.frame
        
        let animator = UIViewPropertyAnimator(duration: animationDuration, dampingRatio: 1) {
            snapshot.frame = context.finalFrame(for: toVC)
        }
        
        animator.addCompletion { (position) in
            
            toVC.additionalSafeAreaInsets = .zero
            toVC.view.frame = context.finalFrame(for: toVC)
            toVC.view.isHidden = false
            
            snapshot.removeFromSuperview()
            if let pipable = toVC as? PictureInPicturable {
                pipable.didExitPiP?()
            }
            
            context.completeTransition(!context.transitionWasCancelled)
        }

        animator.startAnimation()
    }
}

extension PiPAnimator: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch animationType {
        case .enter:
            enterAnimation(context: transitionContext)
        case .exit:
            exitAnimation(context: transitionContext)
        }
    }
    
}
