// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import CommonKit
import UIKit

/// A presenter responsible for showing / hiding a full-screen loading view that obscures (and thus disables) all other controls.
/// It is managed by a `UserIndicator`, meaning the `present` and `dismiss` methods will be called when the parent `UserIndicator` starts or completes.
class FullscreenLoadingViewPresenter: UserIndicatorViewPresentable {
    private let label: String
    private let presentationContext: UserIndicatorPresentationContext
    private weak var view: UIView?
    private var animator: UIViewPropertyAnimator?
    
    init(label: String, presentationContext: UserIndicatorPresentationContext) {
        self.label = label
        self.presentationContext = presentationContext
    }

    func present() {
        // Find the current top navigation controller
        var presentingController: UIViewController? = presentationContext.indicatorPresentingViewController
        while presentingController?.navigationController != nil {
            presentingController = presentingController?.navigationController
        }
        guard let presentingController = presentingController else {
            return
        }
        
        let view = LabelledActivityIndicatorView(text: label)
        view.update(theme: ThemeService.shared().theme)
        self.view = view
        
        view.translatesAutoresizingMaskIntoConstraints = false
        presentingController.view.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: presentingController.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: presentingController.view.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: presentingController.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: presentingController.view.trailingAnchor)
        ])
        
        view.alpha = 0
        animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {
            view.alpha = 1
        }
        animator?.startAnimation()
    }
    
    func dismiss() {
        guard let view = view, view.superview != nil else {
            return
        }
        
        animator?.stopAnimation(true)
        animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeIn) {
            view.alpha = 0
        }
        animator?.addCompletion { _ in
            view.removeFromSuperview()
        }
        animator?.startAnimation()
    }
}
