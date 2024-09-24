// File created from ScreenTemplate
// $ createScreen.sh KeyVerification/Device/ManuallyVerify KeyVerificationManuallyVerify
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

struct KeyVerificationManuallyVerifyViewData {
    let deviceId: String
    let deviceName: String?
    let deviceKey: String?
}

/// KeyVerificationManuallyVerifyViewController view state
enum KeyVerificationManuallyVerifyViewState {
    case loading
    case loaded(_ viewData: KeyVerificationManuallyVerifyViewData)
    case error(Error)
}
