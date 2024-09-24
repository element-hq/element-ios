// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Incoming DeviceVerificationIncoming
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol DeviceVerificationIncomingViewModelViewDelegate: AnyObject {
    func deviceVerificationIncomingViewModel(_ viewModel: DeviceVerificationIncomingViewModelType, didUpdateViewState viewSate: DeviceVerificationIncomingViewState)
}

protocol DeviceVerificationIncomingViewModelCoordinatorDelegate: AnyObject {
    func deviceVerificationIncomingViewModel(_ viewModel: DeviceVerificationIncomingViewModelType, didAcceptTransaction transaction: MXSASTransaction)    
    func deviceVerificationIncomingViewModelDidCancel(_ viewModel: DeviceVerificationIncomingViewModelType)
}

/// Protocol describing the view model used by `DeviceVerificationIncomingViewController`
protocol DeviceVerificationIncomingViewModelType {

    var userId: String { get }
    var userDisplayName: String? { get }
    var avatarUrl: String? { get }
    var deviceId: String { get }

    var mediaManager: MXMediaManager { get }
        
    var viewDelegate: DeviceVerificationIncomingViewModelViewDelegate? { get set }
    var coordinatorDelegate: DeviceVerificationIncomingViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: DeviceVerificationIncomingViewAction)
}
