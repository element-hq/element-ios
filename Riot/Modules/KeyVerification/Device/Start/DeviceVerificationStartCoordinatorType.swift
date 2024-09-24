// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Start DeviceVerificationStart
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol DeviceVerificationStartCoordinatorDelegate: AnyObject {
    func deviceVerificationStartCoordinator(_ coordinator: DeviceVerificationStartCoordinatorType, otherDidAcceptRequest request: MXKeyVerificationRequest)

    func deviceVerificationStartCoordinatorDidCancel(_ coordinator: DeviceVerificationStartCoordinatorType)
}

/// `DeviceVerificationStartCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol DeviceVerificationStartCoordinatorType: Coordinator, Presentable {
    var delegate: DeviceVerificationStartCoordinatorDelegate? { get }
}
