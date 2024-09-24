// File created from ScreenTemplate
// $ createScreen.sh KeyVerification KeyVerificationSelfVerifyStart
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// KeyVerificationSelfVerifyStartViewController view state
enum KeyVerificationSelfVerifyStartViewState {
    case loading
    case loaded
    case verificationPending
    case cancelled(MXTransactionCancelCode)
    case cancelledByMe(MXTransactionCancelCode)
    case error(Error)
}
