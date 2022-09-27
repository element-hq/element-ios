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

// MARK: View model

enum AuthenticationReCaptchaViewModelResult {
    /// Perform the ReCaptcha stage with the associated response.
    case validate(String)
    /// Cancel the flow.
    case cancel
}

// MARK: View

struct AuthenticationReCaptchaViewState: BindableState {
    /// The `sitekey` passed to the ReCaptcha widget.
    let siteKey: String
    /// The homeserver URL used for the web view.
    let homeserverURL: URL
    /// View state that can be bound to from SwiftUI.
    var bindings = AuthenticationReCaptchaBindings()
}

struct AuthenticationReCaptchaBindings {
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<AuthenticationReCaptchaErrorType>?
}

enum AuthenticationReCaptchaViewAction {
    /// Perform the ReCaptcha stage with the associated response.
    case validate(String)
    /// Cancel the flow.
    case cancel
}

enum AuthenticationReCaptchaErrorType: Hashable {
    /// An error response from the homeserver.
    case mxError(String)
    /// An unknown error occurred.
    case unknown
}
