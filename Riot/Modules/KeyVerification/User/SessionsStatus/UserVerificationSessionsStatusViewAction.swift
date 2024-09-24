// File created from ScreenTemplate
// $ createScreen.sh UserVerification UserVerificationSessionsStatus
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// UserVerificationSessionsStatusViewController view actions exposed to view model
enum UserVerificationSessionsStatusViewAction {
    case loadData
    case selectSession(deviceId: String)
    case close
}
