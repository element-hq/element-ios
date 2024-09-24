// File created from ScreenTemplate
// $ createScreen.sh Start UserVerificationStart
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol UserVerificationStartViewModelViewDelegate: AnyObject {
    func userVerificationStartViewModel(_ viewModel: UserVerificationStartViewModelType, didUpdateViewState viewSate: UserVerificationStartViewState)
}

protocol UserVerificationStartViewModelCoordinatorDelegate: AnyObject {
    
    func userVerificationStartViewModel(_ viewModel: UserVerificationStartViewModelType, otherDidAcceptRequest request: MXKeyVerificationRequest)
    
    func userVerificationStartViewModelDidCancel(_ viewModel: UserVerificationStartViewModelType)
}

/// Protocol describing the view model used by `UserVerificationStartViewController`
protocol UserVerificationStartViewModelType {
            
    var viewDelegate: UserVerificationStartViewModelViewDelegate? { get set }
    var coordinatorDelegate: UserVerificationStartViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: UserVerificationStartViewAction)
}
