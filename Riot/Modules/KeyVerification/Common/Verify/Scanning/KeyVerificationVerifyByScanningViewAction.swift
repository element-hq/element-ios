// File created from ScreenTemplate
// $ createScreen.sh Verify KeyVerificationVerifyByScanning
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// KeyVerificationVerifyByScanningViewController view actions exposed to view model
enum KeyVerificationVerifyByScanningViewAction {
    case loadData
    case cancel
    case scannedCode(payloadData: Data)
    case cannotScan    
    case acknowledgeMyUserScannedOtherCode
}
