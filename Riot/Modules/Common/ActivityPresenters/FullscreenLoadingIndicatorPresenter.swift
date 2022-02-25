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
import CommonKit
import UIKit

/// A `UserIndicatorPresentable` responsible for showing / hiding a full-screen loading view that obscures (and thus disables) all other controls.
/// It is managed by a `UserIndicator`, meaning the `present` and `dismiss` methods will be called when the parent `UserIndicator` starts or completes.
class FullscreenLoadingIndicatorPresenter: UserIndicatorPresentable {
    private let label: String
    private weak var viewController: UIViewController?
    private weak var view: UIView?
    
    init(label: String, viewController: UIViewController) {
        self.label = label
        self.viewController = viewController
    }

    func present() {
        // Find the current top navigation controller
        var presentingController: UIViewController? = viewController
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
        UIView.animate(withDuration: 0.2) {
            view.alpha = 1
        }
    }
    
    func dismiss() {
        guard let view = view, view.superview != nil else {
            return
        }
        
        // If `present` and `dismiss` are called right after each other without delay,
        // the view does not correctly pick up `currentState` of alpha. Dispatching onto
        // the main queue skips a few run loops, giving the system time to render
        // current state.
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2, delay: 0, options: .beginFromCurrentState) {
                view.alpha = 0
            } completion: { _ in
                view.removeFromSuperview()
            }
        }
    }
}
