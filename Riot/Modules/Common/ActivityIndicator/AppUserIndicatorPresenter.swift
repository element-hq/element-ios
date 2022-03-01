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

/// Presenter which displays loading spinners using app-wide `AppNavigator`, thus displaying them in a unified way,
/// and `UserIndicatorCenter`/`UserIndicator`, which ensures that only one indicator is shown at a given time.
///
/// Note: clients can skip using `AppUserIndicatorPresenter` and instead coordinate with `AppNavigatorProtocol` directly.
/// The presenter exists mostly as a transition for view controllers already using `ActivityIndicatorPresenterType` and / or view controllers
/// written in objective-c.
@objc final class AppUserIndicatorPresenter: NSObject, ActivityIndicatorPresenterType {
    private let appNavigator: AppNavigatorProtocol
    private var loadingIndicator: UserIndicator?
    private var otherIndicators = [UserIndicator]()
    
    init(appNavigator: AppNavigatorProtocol) {
        self.appNavigator = appNavigator
    }
    
    @objc func presentActivityIndicator() {
        presentActivityIndicator(label: VectorL10n.homeSyncing)
    }

    @objc func presentActivityIndicator(label: String) {
        guard loadingIndicator == nil || loadingIndicator?.state == .completed else {
            // The app is very liberal with calling `presentActivityIndicator` (often not matched by corresponding `removeCurrentActivityIndicator`),
            // so there is no reason to keep adding new indiciators if there is one already showing.
            return
        }

        loadingIndicator = appNavigator.addUserIndicator(.loading(label))
    }
    
    @objc func removeCurrentActivityIndicator(animated: Bool, completion: (() -> Void)?) {
        loadingIndicator = nil
    }
    
    func presentActivityIndicator(on view: UIView, animated: Bool, completion: (() -> Void)?) {
        MXLog.error("[AppUserIndicatorPresenter] Shared indicator presenter does not support presenting from custom views")
    }
    
    @objc func presentSuccess(label: String) {
        appNavigator.addUserIndicator(.success(label)).store(in: &otherIndicators)
    }
}
