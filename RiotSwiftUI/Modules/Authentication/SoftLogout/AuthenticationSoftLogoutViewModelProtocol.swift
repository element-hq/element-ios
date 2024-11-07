//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

protocol AuthenticationSoftLogoutViewModelProtocol {
    var callback: (@MainActor (AuthenticationSoftLogoutViewModelResult) -> Void)? { get set }
    var context: AuthenticationSoftLogoutViewModelType.Context { get }
    
    /// Display an error to the user.
    @MainActor func displayError(_ type: AuthenticationSoftLogoutErrorType)
}
