// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Incoming DeviceVerificationIncoming
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// DeviceVerificationIncomingViewController view state
enum DeviceVerificationIncomingViewState {
    case loading
    case loaded // accepted
    case cancelled(MXTransactionCancelCode)
    case cancelledByMe(MXTransactionCancelCode)
    case error(Error)
}
