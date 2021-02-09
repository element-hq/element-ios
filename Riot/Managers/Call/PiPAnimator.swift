// 
// Copyright 2020 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

@objc enum PiPAnimationType: Int {
    case enter
    case exit
}

@objcMembers
class PiPAnimator: NSObject {
    
    private enum Constants {
        static let pipViewScale: CGFloat = 0.3
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
        
        fromVC.willMove(toParent: nil)
        //  TODO: find a way to call this at the end of animation
        context.completeTransition(true)
        fromVC.removeFromParent()
        
        let pipView = PiPView(frame: fromVC.view.bounds)
        pipView.contentView = fromVC.view
        pipView.delegate = pipViewDelegate
        keyWindow.addSubview(pipView)
        
        let transform = CGAffineTransform(scaleX: Constants.pipViewScale, y: Constants.pipViewScale)
        let targetRect = fromVC.view.bounds.applying(transform)
        
        let animator = UIViewPropertyAnimator(duration: animationDuration, dampingRatio: 1) {
            pipView.transform = transform
            
            pipView.move(in: keyWindow,
                         to: .bottomLeft,
                         targetSize: targetRect.size)
        }
        
        animator.addCompletion { (position) in
            if let pipable = fromVC as? PictureInPicturable {
                pipable.enterPiP?()
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
        
        guard let toVC = context.viewController(forKey: .to),
              let snapshot = toVC.view.snapshotView(afterScreenUpdates: true) else {
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
            toVC.view.isHidden = false
            
            snapshot.removeFromSuperview()
            if let pipable = toVC as? PictureInPicturable {
                pipable.exitPiP?()
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
