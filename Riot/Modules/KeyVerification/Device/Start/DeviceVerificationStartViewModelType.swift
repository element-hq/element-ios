// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Start DeviceVerificationStart
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

protocol DeviceVerificationStartViewModelViewDelegate: AnyObject {
    func deviceVerificationStartViewModel(_ viewModel: DeviceVerificationStartViewModelType, didUpdateViewState viewSate: DeviceVerificationStartViewState)
}

protocol DeviceVerificationStartViewModelCoordinatorDelegate: AnyObject {
    func deviceVerificationStartViewModelDidUseLegacyVerification(_ viewModel: DeviceVerificationStartViewModelType)

    func deviceVerificationStartViewModel(_ viewModel: DeviceVerificationStartViewModelType, didCompleteWithOutgoingTransaction transaction: MXSASTransaction)
    func deviceVerificationStartViewModel(_ viewModel: DeviceVerificationStartViewModelType, didTransactionCancelled transaction: MXSASTransaction)

    func deviceVerificationStartViewModelDidCancel(_ viewModel: DeviceVerificationStartViewModelType)
}

/// Protocol describing the view model used by `DeviceVerificationStartViewController`
protocol DeviceVerificationStartViewModelType {        
    var viewDelegate: DeviceVerificationStartViewModelViewDelegate? { get set }
    var coordinatorDelegate: DeviceVerificationStartViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: DeviceVerificationStartViewAction)
}
