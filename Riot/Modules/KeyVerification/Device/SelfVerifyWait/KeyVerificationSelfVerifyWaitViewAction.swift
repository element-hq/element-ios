// File created from ScreenTemplate
// $ createScreen.sh KeyVerification KeyVerificationSelfVerifyWait
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// KeyVerificationSelfVerifyWaitViewController view actions exposed to view model
enum KeyVerificationSelfVerifyWaitViewAction {
    case loadData
    case cancel
    case recoverSecrets
}
