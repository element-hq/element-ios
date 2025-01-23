//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol AuthenticationReCaptchaViewModelProtocol {
    var callback: (@MainActor (AuthenticationReCaptchaViewModelResult) -> Void)? { get set }
    var context: AuthenticationReCaptchaViewModelType.Context { get }
    
    /// Display an error to the user.
    @MainActor func displayError(_ type: AuthenticationReCaptchaErrorType)
}
