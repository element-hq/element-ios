// File created from ScreenTemplate
// $ createScreen.sh KeyVerification KeyVerificationSelfVerifyStart
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

protocol KeyVerificationSelfVerifyStartViewModelViewDelegate: AnyObject {
    func keyVerificationSelfVerifyStartViewModel(_ viewModel: KeyVerificationSelfVerifyStartViewModelType, didUpdateViewState viewSate: KeyVerificationSelfVerifyStartViewState)
}

protocol KeyVerificationSelfVerifyStartViewModelCoordinatorDelegate: AnyObject {
    func keyVerificationSelfVerifyStartViewModel(_ viewModel: KeyVerificationSelfVerifyStartViewModelType, otherDidAcceptRequest request: MXKeyVerificationRequest)
    func keyVerificationSelfVerifyStartViewModelDidCancel(_ viewModel: KeyVerificationSelfVerifyStartViewModelType)
}

/// Protocol describing the view model used by `KeyVerificationSelfVerifyStartViewController`
protocol KeyVerificationSelfVerifyStartViewModelType {
            
    var viewDelegate: KeyVerificationSelfVerifyStartViewModelViewDelegate? { get set }
    var coordinatorDelegate: KeyVerificationSelfVerifyStartViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: KeyVerificationSelfVerifyStartViewAction)
}
