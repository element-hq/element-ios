// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Loading DeviceVerificationDataLoading
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// KeyVerificationDataLoadingViewController view state
enum KeyVerificationDataLoadingViewState {
    case loading
    case loaded
    case error(Error)
    case errorMessage(String)
}
