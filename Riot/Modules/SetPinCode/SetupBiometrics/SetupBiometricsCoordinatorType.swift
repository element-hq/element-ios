// File created from ScreenTemplate
// $ createScreen.sh SetPinCode/SetupBiometrics SetupBiometrics
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SetupBiometricsCoordinatorDelegate: AnyObject {
    func setupBiometricsCoordinatorDidComplete(_ coordinator: SetupBiometricsCoordinatorType)
    func setupBiometricsCoordinatorDidCompleteWithReset(_ coordinator: SetupBiometricsCoordinatorType, dueToTooManyErrors: Bool)
    func setupBiometricsCoordinatorDidCancel(_ coordinator: SetupBiometricsCoordinatorType)
}

/// `SetupBiometricsCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol SetupBiometricsCoordinatorType: Coordinator, Presentable {
    var delegate: SetupBiometricsCoordinatorDelegate? { get }
}
