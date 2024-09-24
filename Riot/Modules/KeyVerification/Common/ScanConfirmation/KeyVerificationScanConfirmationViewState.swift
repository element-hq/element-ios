// File created from ScreenTemplate
// $ createScreen.sh KeyVerification/Common/ScanConfirmation KeyVerificationScanConfirmation
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

struct KeyVerificationScanConfirmationViewData {
    let isScanning: Bool
    let verificationKind: KeyVerificationKind
    let otherDisplayName: String
}

/// KeyVerificationScanConfirmationViewController view state
enum KeyVerificationScanConfirmationViewState {
    case loading
    case loaded(_ viewData: KeyVerificationScanConfirmationViewData)    
    case cancelled(MXTransactionCancelCode)
    case cancelledByMe(MXTransactionCancelCode)
    case error(Error)
}
