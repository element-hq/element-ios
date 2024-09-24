// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Incoming DeviceVerificationIncoming
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// DeviceVerificationIncomingViewController view actions exposed to view model
enum DeviceVerificationIncomingViewAction {
    case loadData
    case accept
    case cancel
}
