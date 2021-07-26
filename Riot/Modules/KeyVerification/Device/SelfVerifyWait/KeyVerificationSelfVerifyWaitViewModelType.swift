// File created from ScreenTemplate
// $ createScreen.sh KeyVerification KeyVerificationSelfVerifyWait
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

protocol KeyVerificationSelfVerifyWaitViewModelViewDelegate: AnyObject {
    func keyVerificationSelfVerifyWaitViewModel(_ viewModel: KeyVerificationSelfVerifyWaitViewModelType, didUpdateViewState viewSate: KeyVerificationSelfVerifyWaitViewState)
}

protocol KeyVerificationSelfVerifyWaitViewModelCoordinatorDelegate: AnyObject {
    func keyVerificationSelfVerifyWaitViewModel(_ viewModel: KeyVerificationSelfVerifyWaitViewModelType, didAcceptKeyVerificationRequest keyVerificationRequest: MXKeyVerificationRequest)
    func keyVerificationSelfVerifyWaitViewModel(_ viewModel: KeyVerificationSelfVerifyWaitViewModelType, didAcceptIncomingSASTransaction incomingSASTransaction: MXIncomingSASTransaction)
    func keyVerificationSelfVerifyWaitViewModelDidCancel(_ viewModel: KeyVerificationSelfVerifyWaitViewModelType)
    func keyVerificationSelfVerifyWaitViewModel(_ viewModel: KeyVerificationSelfVerifyWaitViewModelType, wantsToRecoverSecretsWith secretsRecoveryMode: SecretsRecoveryMode)
}

/// Protocol describing the view model used by `KeyVerificationSelfVerifyWaitViewController`
protocol KeyVerificationSelfVerifyWaitViewModelType {        
        
    var viewDelegate: KeyVerificationSelfVerifyWaitViewModelViewDelegate? { get set }
    var coordinatorDelegate: KeyVerificationSelfVerifyWaitViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: KeyVerificationSelfVerifyWaitViewAction)
}
