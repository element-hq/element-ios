// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Verify DeviceVerificationVerify
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol KeyVerificationVerifyBySASCoordinatorDelegate: AnyObject {
    func keyVerificationVerifyBySASCoordinatorDidComplete(_ coordinator: KeyVerificationVerifyBySASCoordinatorType)
    func keyVerificationVerifyBySASCoordinatorDidCancel(_ coordinator: KeyVerificationVerifyBySASCoordinatorType)
}

/// `KeyVerificationVerifyBySASCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol KeyVerificationVerifyBySASCoordinatorType: Coordinator, Presentable {
    var delegate: KeyVerificationVerifyBySASCoordinatorDelegate? { get }
}
