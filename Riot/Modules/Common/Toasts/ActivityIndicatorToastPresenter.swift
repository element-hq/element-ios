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

class ActivityIndicatorToastPresenter: ActivityPresentable {
    private weak var view: UIView?
    
    init(text: String, navigationController: UINavigationController) {
        let view = ActivityIndicatorToastView(text: text)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        navigationController.view.addSubview(view)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: navigationController.navigationBar.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: navigationController.navigationBar.bottomAnchor)
        ])
        
        view.isHidden = true
        self.view = view
    }
    
    func present() {
        guard let view = view else {
            return
        }
        
        view.alpha = 0
        view.isHidden = false
        view.transform = .init(translationX: 0, y: 10)
        UIView.animate(withDuration: 0.2) {
            view.alpha = 1
            view.transform = .identity
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
                view.transform = .init(translationX: 0, y: -10)
            } completion: { _ in
                view.removeFromSuperview()
                self.view = nil
            }
        }
    }
}
