// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Verify DeviceVerificationVerify
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// KeyVerificationVerifyBySASViewController view actions exposed to view model
enum KeyVerificationVerifyBySASViewAction {
    case loadData
    case confirm
    case complete
    case cancel
}
