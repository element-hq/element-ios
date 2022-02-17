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

/// An `ActivityPresenter` responsible for showing / hiding a full-screen loading view that obscures (and thus disables) all other controls.
/// It is managed by an `Activity`, meaning the `present` and `dismiss` methods will be called when the parent `Activity` starts or completes.
class FullscreenLoadingActivityPresenter: ActivityPresentable {
    private let label: String
    private weak var viewController: UIViewController?
    private weak var view: UIView?
    
    init(label: String, on viewController: UIViewController) {
        self.label = label
        self.viewController = viewController
    }

    func present() {
        // Find the current top navigation controller
        var vc: UIViewController? = viewController
        while vc?.navigationController != nil {
            vc = vc?.navigationController
        }
        guard let presentingVC = vc else {
            return
        }
        
        let view = LabelledActivityIndicatorView(text: label)
        view.update(theme: ThemeService.shared().theme)
        self.view = view
        
        view.translatesAutoresizingMaskIntoConstraints = false
        presentingVC.view.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: presentingVC.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: presentingVC.view.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: presentingVC.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: presentingVC.view.trailingAnchor)
        ])
        
        view.alpha = 0
        CATransaction.commit()
        UIView.animate(withDuration: 0.2) {
            view.alpha = 1
        }
    }
    
    func dismiss() {
        guard let view = view, view.superview != nil else {
            return
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .beginFromCurrentState) {
            view.alpha = 0
        } completion: { _ in
            view.removeFromSuperview()
        }
    }
}
