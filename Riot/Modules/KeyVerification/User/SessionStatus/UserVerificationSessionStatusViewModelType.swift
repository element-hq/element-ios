// File created from ScreenTemplate
// $ createScreen.sh SessionStatus UserVerificationSessionStatus
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

protocol UserVerificationSessionStatusViewModelViewDelegate: AnyObject {
    func userVerificationSessionStatusViewModel(_ viewModel: UserVerificationSessionStatusViewModelType, didUpdateViewState viewSate: UserVerificationSessionStatusViewState)
}

protocol UserVerificationSessionStatusViewModelCoordinatorDelegate: AnyObject {
    func userVerificationSessionStatusViewModel(_ viewModel: UserVerificationSessionStatusViewModelType, wantsToVerifyDeviceWithId deviceId: String, for userId: String)
    func userVerificationSessionStatusViewModel(_ viewModel: UserVerificationSessionStatusViewModelType, wantsToManuallyVerifyDeviceWithId deviceId: String, for userId: String)
    func userVerificationSessionStatusViewModelDidClose(_ viewModel: UserVerificationSessionStatusViewModelType)
}

/// Protocol describing the view model used by `UserVerificationSessionStatusViewController`
protocol UserVerificationSessionStatusViewModelType {        
        
    var viewDelegate: UserVerificationSessionStatusViewModelViewDelegate? { get set }
    var coordinatorDelegate: UserVerificationSessionStatusViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: UserVerificationSessionStatusViewAction)
}
