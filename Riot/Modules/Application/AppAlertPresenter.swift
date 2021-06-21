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

class AppAlertPresenter: AlertPresentable {
    
    // MARK: - Properties
    
    // swiftlint:disable weak_delegate
    private let legacyAppDelegate: LegacyAppDelegate
    // swiftlint:enable weak_delegate
    
    // MARK: - Setup
    
    init(legacyAppDelegate: LegacyAppDelegate) {
        self.legacyAppDelegate = legacyAppDelegate
    }
    
    // MARK: - Public
 
    func showError(_ error: Error, animated: Bool, completion: (() -> Void)?) {
        // FIXME: Present an error on coordinator.toPresentable()
        self.legacyAppDelegate.showError(asAlert: error)
    }
    
    func show(title: String?, message: String?, animated: Bool, completion: (() -> Void)?) {
        // FIXME: Present an error on coordinator.toPresentable()
        self.legacyAppDelegate.showAlert(withTitle: title, message: message)
    }
}
