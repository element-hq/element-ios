// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit
import CommonKit
import MatrixSDK

/// A presenter responsible for showing / hiding a toast view for loading spinners or success messages.
/// It is managed by an `UserIndicator`, meaning the `present` and `dismiss` methods will be called when the parent `UserIndicator` starts or completes.
class ToastViewPresenter: UserIndicatorViewPresentable {
    private let viewState: ToastViewState
    private let presentationContext: UserIndicatorPresentationContext
    private weak var view: UIView?
    private var animator: UIViewPropertyAnimator?
    
    init(viewState: ToastViewState, presentationContext: UserIndicatorPresentationContext) {
        self.viewState = viewState
        self.presentationContext = presentationContext
    }

    func present() {
        guard let viewController = presentationContext.indicatorPresentingViewController else {
            return
        }
        
        let view = RoundedToastView(viewState: viewState)
        view.update(theme: ThemeService.shared().theme)
        self.view = view
        
        view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(view)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            view.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor)
        ])
        
        view.alpha = 0
        view.transform = .init(translationX: 0, y: 5)
        animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {
            view.alpha = 1
            view.transform = .identity
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
            view.transform = .init(translationX: 0, y: -5)
        }
        animator?.addCompletion { _ in
            view.removeFromSuperview()
        }
        animator?.startAnimation()
    }
}
