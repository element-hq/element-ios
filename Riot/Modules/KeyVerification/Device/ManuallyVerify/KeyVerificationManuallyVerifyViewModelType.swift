// File created from ScreenTemplate
// $ createScreen.sh KeyVerification/Device/ManuallyVerify KeyVerificationManuallyVerify
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol KeyVerificationManuallyVerifyViewModelViewDelegate: AnyObject {
    func keyVerificationManuallyVerifyViewModel(_ viewModel: KeyVerificationManuallyVerifyViewModelType, didUpdateViewState viewSate: KeyVerificationManuallyVerifyViewState)
}

protocol KeyVerificationManuallyVerifyViewModelCoordinatorDelegate: AnyObject {
    func keyVerificationManuallyVerifyViewModel(_ viewModel: KeyVerificationManuallyVerifyViewModelType, didVerifiedDeviceWithId deviceId: String, of userId: String)
    func keyVerificationManuallyVerifyViewModelDidCancel(_ viewModel: KeyVerificationManuallyVerifyViewModelType)
}

/// Protocol describing the view model used by `KeyVerificationManuallyVerifyViewController`
protocol KeyVerificationManuallyVerifyViewModelType {        
        
    var viewDelegate: KeyVerificationManuallyVerifyViewModelViewDelegate? { get set }
    var coordinatorDelegate: KeyVerificationManuallyVerifyViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: KeyVerificationManuallyVerifyViewAction)
}
