// File created from ScreenTemplate
// $ createScreen.sh SetPinCode/EnterPinCode EnterPinCode
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// EnterPinCodeViewController view actions exposed to view model
enum EnterPinCodeViewAction {
    case loadData
    case digitPressed(_ tag: Int)
    case forgotPinPressed
    case cancel
    case pinsDontMatchAlertAction
    case forgotPinAlertResetAction
    case forgotPinAlertCancelAction
}
