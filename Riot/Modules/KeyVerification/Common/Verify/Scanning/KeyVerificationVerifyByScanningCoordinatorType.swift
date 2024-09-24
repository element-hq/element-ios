// File created from ScreenTemplate
// $ createScreen.sh Verify KeyVerificationVerifyByScanning
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol KeyVerificationVerifyByScanningCoordinatorDelegate: AnyObject {
    func keyVerificationVerifyByScanningCoordinatorDidCancel(_ coordinator: KeyVerificationVerifyByScanningCoordinatorType)    
    func keyVerificationVerifyByScanningCoordinator(_ coordinator: KeyVerificationVerifyByScanningCoordinatorType, didScanOtherQRCodeData qrCodeData: MXQRCodeData, withTransaction transaction: MXQRCodeTransaction)
    func keyVerificationVerifyByScanningCoordinator(_ coordinator: KeyVerificationVerifyByScanningCoordinatorType, qrCodeDidScannedByOtherWithTransaction transaction: MXQRCodeTransaction)    
    func keyVerificationVerifyByScanningCoordinator(_ coordinator: KeyVerificationVerifyByScanningCoordinatorType, didCompleteWithSASTransaction transaction: MXSASTransaction)
}

/// `KeyVerificationVerifyByScanningCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol KeyVerificationVerifyByScanningCoordinatorType: Coordinator, Presentable {
    var delegate: KeyVerificationVerifyByScanningCoordinatorDelegate? { get }
}
