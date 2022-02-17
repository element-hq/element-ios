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

/// An `ActivityPresenter` responsible for showing / hiding a toast view for activity indicators or success messages.
/// It is managed by an `Activity`, meaning the `present` and `dismiss` methods will be called when the parent `Activity` starts or completes.
class ToastActivityPresenter: ActivityPresentable {
    private let viewState: RoundedToastView.ViewState
    private weak var navigationController: UINavigationController?
    private weak var view: UIView?
    
    init(viewState: RoundedToastView.ViewState, navigationController: UINavigationController) {
        self.viewState = viewState
        self.navigationController = navigationController
    }

    func present() {
        guard let navigationController = navigationController else {
            return
        }
        
        let view = RoundedToastView(viewState: viewState)
        view.update(theme: ThemeService.shared().theme)
        self.view = view
        
        view.translatesAutoresizingMaskIntoConstraints = false
        navigationController.view.addSubview(view)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: navigationController.navigationBar.centerXAnchor),
            view.topAnchor.constraint(equalTo: navigationController.navigationBar.bottomAnchor)
        ])
        
        view.alpha = 0
        CATransaction.flush()
        view.transform = .init(translationX: 0, y: 5)
        
        UIView.animate(withDuration: 0.2) {
            view.alpha = 1
            view.transform = .identity
        }
    }
    
    func dismiss() {
        guard let view = view, view.superview != nil else {
            return
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .beginFromCurrentState) {
            view.alpha = 0
            view.transform = .init(translationX: 0, y: -5)
        } completion: { _ in
            view.removeFromSuperview()
        }
    }
}
