// File created from ScreenTemplate
// $ createScreen.sh Modal/Show ServiceTermsModalScreen
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// ServiceTermsModalScreenViewController view actions exposed to view model
enum ServiceTermsModalScreenViewAction {
    case load
    case display(MXLoginPolicyData)
    case accept
    case decline
}
