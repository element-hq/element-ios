// File created from ScreenTemplate
// $ createScreen.sh Verify KeyVerificationVerifyByScanning
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol KeyVerificationVerifyByScanningViewModelViewDelegate: AnyObject {
    func keyVerificationVerifyByScanningViewModel(_ viewModel: KeyVerificationVerifyByScanningViewModelType, didUpdateViewState viewSate: KeyVerificationVerifyByScanningViewState)
}

protocol KeyVerificationVerifyByScanningViewModelCoordinatorDelegate: AnyObject {
    func keyVerificationVerifyByScanningViewModelDidCancel(_ viewModel: KeyVerificationVerifyByScanningViewModelType)
    
    func keyVerificationVerifyByScanningViewModel(_ viewModel: KeyVerificationVerifyByScanningViewModelType, didScanOtherQRCodeData qrCodeData: MXQRCodeData, withTransaction transaction: MXQRCodeTransaction)
    
    func keyVerificationVerifyByScanningViewModel(_ viewModel: KeyVerificationVerifyByScanningViewModelType, qrCodeDidScannedByOtherWithTransaction transaction: MXQRCodeTransaction)
    
    func keyVerificationVerifyByScanningViewModel(_ viewModel: KeyVerificationVerifyByScanningViewModelType, didStartSASVerificationWithTransaction transaction: MXSASTransaction)
}

/// Protocol describing the view model used by `KeyVerificationVerifyByScanningViewController`
protocol KeyVerificationVerifyByScanningViewModelType {
            
    var viewDelegate: KeyVerificationVerifyByScanningViewModelViewDelegate? { get set }
    var coordinatorDelegate: KeyVerificationVerifyByScanningViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: KeyVerificationVerifyByScanningViewAction)
}
