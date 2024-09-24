// File created from ScreenTemplate
// $ createScreen.sh SessionStatus UserVerificationSessionStatus
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// UserVerificationSessionStatusViewController view state
enum UserVerificationSessionStatusViewState {
    case loading
    case loaded(viewData: SessionStatusViewData)
    case error(Error)
}
