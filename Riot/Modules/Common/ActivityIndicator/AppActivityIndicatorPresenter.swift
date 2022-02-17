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
import MatrixSDK
import CommonKit

/// Presenter which displays activity / loading indicators using app-wide `AppNavigator`, thus displaying them in a unified way,
/// and `ActivityCenter`/`Activity`, which ensures that only one activity is shown at a given time.
///
/// Note: clients can skip using `AppActivityIndicatorPresenter` and instead coordiinate with `AppNavigatorProtocol` directly.
/// The presenter exists mostly as a transition for view controllers already using `ActivityIndicatorPresenterType` and / or view controllers
/// written in objective-c.
@objc final class AppActivityIndicatorPresenter: NSObject, ActivityIndicatorPresenterType {
    private let appNavigator: AppNavigatorProtocol
    private var activity: Activity?
    
    init(appNavigator: AppNavigatorProtocol) {
        self.appNavigator = appNavigator
    }

    @objc func presentActivityIndicator() {
        activity = appNavigator.addLoadingActivity()
    }
    
    @objc func removeCurrentActivityIndicator(animated: Bool, completion: (() -> Void)?) {
        activity = nil
    }
    
    func presentActivityIndicator(on view: UIView, animated: Bool, completion: (() -> Void)?) {
        MXLog.error("[AppActivityIndicatorPresenter] Shared activity indicator does not support presenting from custom views")
    }
}
