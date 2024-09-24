// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Start DeviceVerificationStart
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol DeviceVerificationStartViewModelViewDelegate: AnyObject {
    func deviceVerificationStartViewModel(_ viewModel: DeviceVerificationStartViewModelType, didUpdateViewState viewSate: DeviceVerificationStartViewState)
}

protocol DeviceVerificationStartViewModelCoordinatorDelegate: AnyObject {
    func deviceVerificationStartViewModelDidUseLegacyVerification(_ viewModel: DeviceVerificationStartViewModelType)

    func deviceVerificationStartViewModel(_ viewModel: DeviceVerificationStartViewModelType, otherDidAcceptRequest request: MXKeyVerificationRequest)

    func deviceVerificationStartViewModelDidCancel(_ viewModel: DeviceVerificationStartViewModelType)
}

/// Protocol describing the view model used by `DeviceVerificationStartViewController`
protocol DeviceVerificationStartViewModelType {        
    var viewDelegate: DeviceVerificationStartViewModelViewDelegate? { get set }
    var coordinatorDelegate: DeviceVerificationStartViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: DeviceVerificationStartViewAction)
}
