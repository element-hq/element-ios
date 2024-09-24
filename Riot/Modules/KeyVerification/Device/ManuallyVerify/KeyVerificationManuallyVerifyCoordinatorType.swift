// File created from ScreenTemplate
// $ createScreen.sh KeyVerification/Device/ManuallyVerify KeyVerificationManuallyVerify
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol KeyVerificationManuallyVerifyCoordinatorDelegate: AnyObject {
    func keyVerificationManuallyVerifyCoordinator(_ coordinator: KeyVerificationManuallyVerifyCoordinatorType, didVerifiedDeviceWithId deviceId: String, of userId: String)    
    func keyVerificationManuallyVerifyCoordinatorDidCancel(_ coordinator: KeyVerificationManuallyVerifyCoordinatorType)
}

/// `KeyVerificationManuallyVerifyCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol KeyVerificationManuallyVerifyCoordinatorType: Coordinator, Presentable {
    var delegate: KeyVerificationManuallyVerifyCoordinatorDelegate? { get }
}
