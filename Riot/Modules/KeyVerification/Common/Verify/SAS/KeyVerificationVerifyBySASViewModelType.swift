// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Verify DeviceVerificationVerify
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

protocol KeyVerificationVerifyBySASViewModelViewDelegate: AnyObject {
    func keyVerificationVerifyBySASViewModel(_ viewModel: KeyVerificationVerifyBySASViewModelType, didUpdateViewState viewSate: KeyVerificationVerifyViewState)
}

protocol KeyVerificationVerifyBySASViewModelCoordinatorDelegate: AnyObject {
    func keyVerificationVerifyViewModelDidComplete(_ viewModel: KeyVerificationVerifyBySASViewModelType)    
    func keyVerificationVerifyViewModelDidCancel(_ viewModel: KeyVerificationVerifyBySASViewModelType)
}

/// Protocol describing the view model used by `KeyVerificationVerifyBySASViewController`
protocol KeyVerificationVerifyBySASViewModelType {
        
    var viewDelegate: KeyVerificationVerifyBySASViewModelViewDelegate? { get set }
    var coordinatorDelegate: KeyVerificationVerifyBySASViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: KeyVerificationVerifyBySASViewAction)

    var emojis: [MXEmojiRepresentation]? { get }
    var decimal: String? { get }
    var verificationKind: KeyVerificationKind { get }
}
