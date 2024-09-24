// File created from ScreenTemplate
// $ createScreen.sh SetPinCode/SetupBiometrics SetupBiometrics
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SetupBiometricsViewController view state
enum SetupBiometricsViewState {
    case setupAfterLogin
    case setupFromSettings
    case unlock
    case confirmToDisable
    case cantUnlocked
}
