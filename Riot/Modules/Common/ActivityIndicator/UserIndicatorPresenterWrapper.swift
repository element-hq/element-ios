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

/// A convenience objc-compatible wrapper around `UserIndicatorTypePresenterProtocol`.
///
/// This class wraps swift-only protocol by exposing multiple methods instead of accepting struct types
/// and it keeps a track of `UserIndicator`s instead of returning them to the caller.
@objc final class UserIndicatorPresenterWrapper: NSObject {
    private let presenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    private var otherIndicators = [UserIndicator]()
    
    init(presenter: UserIndicatorTypePresenterProtocol) {
        self.presenter = presenter
    }
    
    @objc func presentLoadingIndicator() {
        presentLoadingIndicator(label: VectorL10n.homeSyncing)
    }

    @objc func presentLoadingIndicator(label: String) {
        guard loadingIndicator == nil else {
            // The app is very liberal with calling `presentLoadingIndicator` (often not matched by corresponding `dismissLoadingIndicator`),
            // so there is no reason to keep adding new indiciators if there is one already showing.
            return
        }

        MXLog.debug("[UserIndicatorPresenterWrapper] Present loading indicator")
        loadingIndicator = presenter.present(.loading(label: label, isInteractionBlocking: false))
    }
    
    @objc func dismissLoadingIndicator() {
        MXLog.debug("[UserIndicatorPresenterWrapper] Dismiss loading indicator")
        loadingIndicator = nil
    }
    
    @objc func presentSuccess(label: String) {
        presenter.present(.success(label: label)).store(in: &otherIndicators)
    }
}
