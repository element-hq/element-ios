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

protocol DeviceVerificationVerifyViewModelViewDelegate: class {
    func deviceVerificationVerifyViewModel(_ viewModel: DeviceVerificationVerifyViewModelType, didUpdateViewState viewSate: DeviceVerificationVerifyViewState)
}

protocol DeviceVerificationVerifyViewModelCoordinatorDelegate: class {
    func deviceVerificationVerifyViewModelDidComplete(_ viewModel: DeviceVerificationVerifyViewModelType)    
    func deviceVerificationVerifyViewModelDidCancel(_ viewModel: DeviceVerificationVerifyViewModelType)
}

/// Protocol describing the view model used by `DeviceVerificationVerifyViewController`
protocol DeviceVerificationVerifyViewModelType {
        
    var viewDelegate: DeviceVerificationVerifyViewModelViewDelegate? { get set }
    var coordinatorDelegate: DeviceVerificationVerifyViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: DeviceVerificationVerifyViewAction)

    var emojis: [MXEmojiRepresentation]? { get set }
    var decimal: String? { get set }
}
