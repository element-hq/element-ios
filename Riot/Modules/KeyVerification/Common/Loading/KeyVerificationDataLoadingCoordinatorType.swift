// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Loading DeviceVerificationDataLoading
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol KeyVerificationDataLoadingCoordinatorDelegate: AnyObject {
    func keyVerificationDataLoadingCoordinator(_ coordinator: KeyVerificationDataLoadingCoordinatorType, didLoadUser user: MXUser, device: MXDeviceInfo)
    func keyVerificationDataLoadingCoordinator(_ coordinator: KeyVerificationDataLoadingCoordinatorType, didAcceptKeyVerificationRequestWithTransaction transaction: MXKeyVerificationTransaction)
    func keyVerificationDataLoadingCoordinator(_ coordinator: KeyVerificationDataLoadingCoordinatorType, didAcceptKeyVerificationRequest keyVerificationRequest: MXKeyVerificationRequest)
    func keyVerificationDataLoadingCoordinatorDidCancel(_ coordinator: KeyVerificationDataLoadingCoordinatorType)
}

/// `KeyVerificationDataLoadingCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol KeyVerificationDataLoadingCoordinatorType: Coordinator, Presentable {
    var delegate: KeyVerificationDataLoadingCoordinatorDelegate? { get }
}
