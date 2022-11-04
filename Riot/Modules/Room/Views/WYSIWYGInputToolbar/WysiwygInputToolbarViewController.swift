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
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let toView = transitionContext.view(forKey: .to)!
    }
}

final class WysiwygInputToolbarViewController: UIViewController {
    private let wysiwygInputToolbarView: WysiwygInputToolbarView
    private let transition = SheetAnimator()
    
    init(view: WysiwygInputToolbarView){
        self.wysiwygInputToolbarView = view
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = self
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(wysiwygInputToolbarView)
        NSLayoutConstraint.activate(
            [
                self.view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: wysiwygInputToolbarView.bottomAnchor),
                self.view.safeAreaLayoutGuide.leftAnchor.constraint(equalTo: wysiwygInputToolbarView.leftAnchor),
                self.view.safeAreaLayoutGuide.rightAnchor.constraint(equalTo: wysiwygInputToolbarView.rightAnchor),
                self.view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: wysiwygInputToolbarView.topAnchor)
            ]
        )
    }
}

extension WysiwygInputToolbarViewController: UIViewControllerTransitioningDelegate {
    func animationController(
      forPresented presented: UIViewController,
      presenting: UIViewController, source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
      return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
      return nil
    }
}
