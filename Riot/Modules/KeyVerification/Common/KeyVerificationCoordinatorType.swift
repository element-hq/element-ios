// File created from FlowTemplate
// $ createRootCoordinator.sh DeviceVerification DeviceVerification DeviceVerificationStart
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol KeyVerificationCoordinatorDelegate: AnyObject {
    func keyVerificationCoordinatorDidComplete(_ coordinator: KeyVerificationCoordinatorType, otherUserId: String, otherDeviceId: String)
    func keyVerificationCoordinatorDidCancel(_ coordinator: KeyVerificationCoordinatorType)
}

/// `KeyVerificationCoordinatorType` is a protocol describing a Coordinator that handle key verification navigation flow.
protocol KeyVerificationCoordinatorType: Coordinator, Presentable {
    var delegate: KeyVerificationCoordinatorDelegate? { get }
}
