// File created from ScreenTemplate
// $ createScreen.sh KeyVerification/Common/ScanConfirmation KeyVerificationScanConfirmation
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol KeyVerificationScanConfirmationCoordinatorDelegate: AnyObject {
    func keyVerificationScanConfirmationCoordinatorDidComplete(_ coordinator: KeyVerificationScanConfirmationCoordinatorType)
    func keyVerificationScanConfirmationCoordinatorDidCancel(_ coordinator: KeyVerificationScanConfirmationCoordinatorType)
}

/// `KeyVerificationScanConfirmationCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol KeyVerificationScanConfirmationCoordinatorType: Coordinator, Presentable {
    var delegate: KeyVerificationScanConfirmationCoordinatorDelegate? { get }
}
