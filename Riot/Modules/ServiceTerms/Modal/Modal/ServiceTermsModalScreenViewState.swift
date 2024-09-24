// File created from ScreenTemplate
// $ createScreen.sh Modal/Show ServiceTermsModalScreen
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// ServiceTermsModalScreenViewController view state
enum ServiceTermsModalScreenViewState {
    case loading
    case loaded(policies: [MXLoginPolicyData], alreadyAcceptedPoliciesUrls: [String])
    case accepted
    case error(Error)
}
