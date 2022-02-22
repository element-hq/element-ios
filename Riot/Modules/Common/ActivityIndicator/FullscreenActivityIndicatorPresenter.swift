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

/// Presenter which displays fullscreen loading spinners, and conforming to legacy `ActivityIndicatorPresenterType`,
/// but interally wrapping an `UserIndicatorPresenter` which is used in conjuction with `UserIndicator` and `UserIndicatorQueue`.
///
/// Note: clients can skip using `FullscreenActivityIndicatorPresenter` and instead coordiinate with `AppNavigatorProtocol` directly.
/// The presenter exists mostly as a transition for view controllers already using `ActivityIndicatorPresenterType` and / or view controllers
/// written in objective-c.
@objc final class FullscreenActivityIndicatorPresenter: NSObject, ActivityIndicatorPresenterType {
    private let label: String
    private weak var viewController: UIViewController?
    private var indicator: UserIndicator?
    
    init(label: String, on viewController: UIViewController) {
        self.label = label
        self.viewController = viewController
    }
    
    func presentActivityIndicator(on view: UIView, animated: Bool, completion: (() -> Void)?) {
        guard let vc = viewController else {
            return
        }
        
        let request = UserIndicatorRequest(
            presenter: FullscreenLoadingIndicatorPresenter(label: label, on: vc),
            dismissal: .manual
        )
        
        indicator = UserIndicatorQueue.shared.add(request)
    }
    
    @objc func removeCurrentActivityIndicator(animated: Bool, completion: (() -> Void)?) {
        indicator?.cancel()
    }
}
