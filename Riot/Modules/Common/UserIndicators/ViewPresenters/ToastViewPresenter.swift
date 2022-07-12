// 
// Copyright 2021 New Vector Ltd
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
import UIKit
import CommonKit
import MatrixSDK

/// A presenter responsible for showing / hiding a toast view for loading spinners or success messages.
/// It is managed by an `UserIndicator`, meaning the `present` and `dismiss` methods will be called when the parent `UserIndicator` starts or completes.
class ToastViewPresenter: UserIndicatorViewPresentable {
    struct Constants {
        static let navigationBarPatting = CGFloat(12)
    }
    
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
        if let navigation = viewController.topNavigationController {
            navigation.view.addSubview(view)
            NSLayoutConstraint.activate([
                view.centerXAnchor.constraint(equalTo: navigation.view.centerXAnchor),
                view.topAnchor.constraint(equalTo: navigation.navigationBar.safeAreaLayoutGuide.bottomAnchor, constant: Constants.navigationBarPatting)
            ])
        } else {
            viewController.view.addSubview(view)
            NSLayoutConstraint.activate([
                view.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
                view.topAnchor.constraint(equalTo: viewController.view.topAnchor)
            ])
        }
        
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

private extension UIViewController {
    var topNavigationController: UINavigationController? {
        var controller: UINavigationController? = self as? UINavigationController ?? navigationController
        while controller?.navigationController != nil {
            controller = controller?.navigationController
        }
        return controller
    }
}
