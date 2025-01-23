//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
