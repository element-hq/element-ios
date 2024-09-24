// File created from ScreenTemplate
// $ createScreen.sh Verify KeyVerificationVerifyByScanning
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

struct KeyVerificationVerifyByScanningViewData {
    let verificationKind: KeyVerificationKind
    let qrCodeData: Data?
    let showScanAction: Bool
}

/// KeyVerificationVerifyByScanningViewController view state
enum KeyVerificationVerifyByScanningViewState {
    case loading
    case loaded(viewData: KeyVerificationVerifyByScanningViewData)
    case scannedCodeValidated(isValid: Bool)    
    case cancelled(cancelCode: MXTransactionCancelCode, verificationKind: KeyVerificationKind)
    case cancelledByMe(MXTransactionCancelCode)
    case error(Error)
}
