//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol AuthenticationChoosePasswordViewModelProtocol {
    var callback: (@MainActor (AuthenticationChoosePasswordViewModelResult) -> Void)? { get set }
    var context: AuthenticationChoosePasswordViewModelType.Context { get }
    
    /// Display an error to the user.
    @MainActor func displayError(_ type: AuthenticationChoosePasswordErrorType)
}
