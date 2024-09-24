// File created from ScreenTemplate
// $ createScreen.sh Start UserVerificationStart
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// UserVerificationStartViewController view actions exposed to view model
enum UserVerificationStartViewAction {
    case loadData
    case startVerification
    case cancel
}
