// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Incoming DeviceVerificationIncoming
/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
