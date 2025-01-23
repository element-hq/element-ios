//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol AuthenticationVerifyMsisdnViewModelProtocol {
    var callback: (@MainActor (AuthenticationVerifyMsisdnViewModelResult) -> Void)? { get set }
    var context: AuthenticationVerifyMsisdnViewModelType.Context { get }
    
    /// Updates the view to reflect that a verification SMS was successfully sent.
    @MainActor func updateForSentSMS()

    //  Goes back to the msisdn form
    @MainActor func goBackToMsisdnForm()
    
    /// Display an error to the user.
    @MainActor func displayError(_ type: AuthenticationVerifyMsisdnErrorType)
}
