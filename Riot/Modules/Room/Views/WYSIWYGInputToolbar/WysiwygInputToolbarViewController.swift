// 
// Copyright 2022 New Vector Ltd
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

class SheetAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let duration = 1.0
    var presenting = true
    var originFrame = CGRect.zero
    var dismissCompletion: (() -> ())?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let toView = transitionContext.view(forKey: .to)!
        let toolbarView = presenting ? toView : transitionContext.view(forKey: .from)!
        let finalFrame = presenting ? originFrame : toolbarView.frame
        let initialFrame = presenting ? toolbarView.frame : originFrame
        if presenting {
          toolbarView.center =  CGPoint(x: initialFrame.midX, y: initialFrame.midY)
          toolbarView.clipsToBounds = true
        }
        toolbarView.layer.cornerRadius = presenting ? 20.0 : 0.0
        toolbarView.layer.masksToBounds = true
        containerView.addSubview(toView)
        containerView.bringSubviewToFront(toolbarView)
        UIView.animate(
          withDuration: duration,
          animations: {
            toolbarView.center = CGPoint(x: finalFrame.midX, y: finalFrame.midY + 500)
            toolbarView.layer.cornerRadius = !self.presenting ? 20.0 : 0.0
          }, completion: { _ in
            transitionContext.completeTransition(true)
        })
    }
}

final class WysiwygInputToolbarViewController: UIViewController {
    private let transition = SheetAnimator()
    
    private var wysiwygInputToolbar: WysiwygInputToolbarView? {
        return view as? WysiwygInputToolbarView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.transitioningDelegate = self
        self.modalPresentationStyle = .custom
    }
}

extension WysiwygInputToolbarViewController: UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController, source: UIViewController)
    -> UIViewControllerAnimatedTransitioning? {
        transition.presenting = true
        if let roomViewController = source as? RoomViewController,
           let inputToolbarView = roomViewController.inputToolbarView,
            let inputToolbarSuperview = inputToolbarView.superview {
            transition.originFrame = inputToolbarSuperview.convert(inputToolbarView.frame, to: nil)
        }
        return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController)
    -> UIViewControllerAnimatedTransitioning? {
        transition.presenting = false
        return transition
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
            return SheethPresentationController(presentedViewController: presented, presenting: presenting ?? source)
        }
}

final class SheethPresentationController: UIPresentationController {
}
