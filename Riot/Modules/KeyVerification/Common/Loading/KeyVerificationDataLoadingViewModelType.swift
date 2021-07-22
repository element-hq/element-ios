// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Loading DeviceVerificationDataLoading
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

protocol KeyVerificationDataLoadingViewModelViewDelegate: AnyObject {
    func keyVerificationDataLoadingViewModel(_ viewModel: KeyVerificationDataLoadingViewModelType, didUpdateViewState viewSate: KeyVerificationDataLoadingViewState)
}

protocol KeyVerificationDataLoadingViewModelCoordinatorDelegate: AnyObject {
    func keyVerificationDataLoadingViewModel(_ viewModel: KeyVerificationDataLoadingViewModelType, didLoadUser user: MXUser, device: MXDeviceInfo)
    func keyVerificationDataLoadingViewModel(_ viewModel: KeyVerificationDataLoadingViewModelType, didAcceptKeyVerificationWithTransaction transaction: MXKeyVerificationTransaction)
    func keyVerificationDataLoadingViewModel(_ viewModel: KeyVerificationDataLoadingViewModelType, didAcceptKeyVerificationRequest keyVerificationRequest: MXKeyVerificationRequest)
    func keyVerificationDataLoadingViewModelDidCancel(_ viewModel: KeyVerificationDataLoadingViewModelType)
}

/// Protocol describing the view model used by `KeyVerificationDataLoadingViewController`
protocol KeyVerificationDataLoadingViewModelType {
        
    var viewDelegate: KeyVerificationDataLoadingViewModelViewDelegate? { get set }
    var coordinatorDelegate: KeyVerificationDataLoadingViewModelCoordinatorDelegate? { get set }
    
    var verificationKind: KeyVerificationKind { get }
    
    func process(viewAction: KeyVerificationDataLoadingViewAction)
}
