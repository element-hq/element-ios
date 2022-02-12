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

/// Activity indicator presenter which uses a shared `ActivityCenter` to coordinate different activity indicators,
/// and which uses the root navigation view controller to display the activities.
@objc final class GlobalActivityCenterPresenter: NSObject, ActivityIndicatorPresenterType {
    private var loadingActivity: Activity?
    
    private var rootNavigationController: UINavigationController? {
        guard
            let delegate = UIApplication.shared.delegate as? AppDelegate,
            let rootVC = delegate.window?.rootViewController
        else {
            MXLog.error("[ActivityIndicatorPresenter] Missing root view controller")
            return nil
        }
        
        if let vc = (rootVC as? UISplitViewController)?.viewControllers.first as? UINavigationController {
            return vc
        } else if let vc = rootVC as? UINavigationController {
            return vc
        } else if let vc = rootVC.navigationController {
            return vc
        }
        return nil
    }

    @objc func presentActivityIndicator(animated: Bool) {
        guard let vc = rootNavigationController else {
            MXLog.error("[ActivityIndicatorPresenter] Missing available navigation controller")
            return
        }
        
        let presenter = ActivityIndicatorToastPresenter(
            text: VectorL10n.roomParticipantsSecurityLoading,
            navigationController: vc
        )
        let request = ActivityRequest(
            presenter: presenter,
            dismissal: .manual
        )
        loadingActivity = ActivityCenter.shared.add(request)
    }
    
    func presentActivityIndicator(on view: UIView, animated: Bool, completion: (() -> Void)?) {
        MXLog.error("[ActivityIndicatorPresenter] Shared activity indicator needs to be presented on a view controller")
    }
    
    @objc func removeCurrentActivityIndicator(animated: Bool, completion: (() -> Void)?) {
        loadingActivity = nil
    }
}
