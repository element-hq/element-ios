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

/// Presenter which displays fullscreen activity / loading indicators, and conforming to legacy `ActivityIndicatorPresenterType`,
/// but interally wrapping an `ActivityPresenter` which is used in conjuction to `Activity` and `ActivityCenter`.
///
/// Note: clients can skip using `FullscreenActivityIndicatorPresenter` and instead coordiinate with `AppNavigatorProtocol` directly.
/// The presenter exists mostly as a transition for view controllers already using `ActivityIndicatorPresenterType` and / or view controllers
/// written in objective-c.
@objc final class FullscreenActivityIndicatorPresenter: NSObject, ActivityIndicatorPresenterType {
    private let label: String
    private weak var viewController: UIViewController?
    private var activity: Activity?
    
    init(label: String, on viewController: UIViewController) {
        self.label = label
        self.viewController = viewController
    }
    
    func presentActivityIndicator(on view: UIView, animated: Bool, completion: (() -> Void)?) {
        guard let vc = viewController else {
            return
        }
        
        let request = ActivityRequest(
            presenter: FullscreenLoadingActivityPresenter(label: label, on: vc),
            dismissal: .manual
        )
        
        activity = ActivityCenter.shared.add(request)
    }
    
    @objc func removeCurrentActivityIndicator(animated: Bool, completion: (() -> Void)?) {
        activity?.cancel()
    }
}
