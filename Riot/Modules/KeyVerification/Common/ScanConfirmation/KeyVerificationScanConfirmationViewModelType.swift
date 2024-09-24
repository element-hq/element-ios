// File created from ScreenTemplate
// $ createScreen.sh KeyVerification/Common/ScanConfirmation KeyVerificationScanConfirmation
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol KeyVerificationScanConfirmationViewModelViewDelegate: AnyObject {
    func keyVerificationScanConfirmationViewModel(_ viewModel: KeyVerificationScanConfirmationViewModelType, didUpdateViewState viewSate: KeyVerificationScanConfirmationViewState)
}

protocol KeyVerificationScanConfirmationViewModelCoordinatorDelegate: AnyObject {
    func keyVerificationScanConfirmationViewModelDidComplete(_ viewModel: KeyVerificationScanConfirmationViewModelType)
    func keyVerificationScanConfirmationViewModelDidCancel(_ viewModel: KeyVerificationScanConfirmationViewModelType)
}

/// Protocol describing the view model used by `KeyVerificationScanConfirmationViewController`
protocol KeyVerificationScanConfirmationViewModelType {        
        
    var viewDelegate: KeyVerificationScanConfirmationViewModelViewDelegate? { get set }
    var coordinatorDelegate: KeyVerificationScanConfirmationViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: KeyVerificationScanConfirmationViewAction)
}
