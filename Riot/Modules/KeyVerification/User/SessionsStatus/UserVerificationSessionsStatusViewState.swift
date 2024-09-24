// File created from ScreenTemplate
// $ createScreen.sh UserVerification UserVerificationSessionsStatus
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// UserVerificationSessionsStatusViewController view state
enum UserVerificationSessionsStatusViewState {
    case loading
    case loaded(userTrustLevel: UserEncryptionTrustLevel, sessionsStatusViewData: [UserVerificationSessionStatusViewData])
    case error(Error)
}
