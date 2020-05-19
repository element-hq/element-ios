// File created from ScreenTemplate
// $ createScreen.sh KeyVerification/Common/ScanConfirmation KeyVerificationScanConfirmation
/*
 Copyright 2020 New Vector Ltd
 
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

protocol KeyVerificationScanConfirmationViewModelViewDelegate: class {
    func keyVerificationScanConfirmationViewModel(_ viewModel: KeyVerificationScanConfirmationViewModelType, didUpdateViewState viewSate: KeyVerificationScanConfirmationViewState)
}

protocol KeyVerificationScanConfirmationViewModelCoordinatorDelegate: class {
    func keyVerificationScanConfirmationViewModelDidComplete(_ viewModel: KeyVerificationScanConfirmationViewModelType)
    func keyVerificationScanConfirmationViewModelDidCancel(_ viewModel: KeyVerificationScanConfirmationViewModelType)
}

/// Protocol describing the view model used by `KeyVerificationScanConfirmationViewController`
protocol KeyVerificationScanConfirmationViewModelType {        
        
    var viewDelegate: KeyVerificationScanConfirmationViewModelViewDelegate? { get set }
    var coordinatorDelegate: KeyVerificationScanConfirmationViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: KeyVerificationScanConfirmationViewAction)
}
