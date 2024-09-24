// File created from ScreenTemplate
// $ createScreen.sh KeyVerification/Common/ScanConfirmation KeyVerificationScanConfirmation
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// KeyVerificationScanConfirmationViewController view actions exposed to view model
enum KeyVerificationScanConfirmationViewAction {
    case loadData
    case acknowledgeOtherScannedMyCode(_ otherScannedMyCode: Bool)
    case cancel
}
