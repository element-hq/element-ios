// File created from ScreenTemplate
// $ createScreen.sh Start UserVerificationStart
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// UserVerificationStartViewController view state
enum UserVerificationStartViewState {
    case loading
    case loaded(UserVerificationStartViewData)
    case verificationPending
    case cancelled(MXTransactionCancelCode)
    case cancelledByMe(MXTransactionCancelCode)
    case error(Error)
}
