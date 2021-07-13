// File created from ScreenTemplate
// $ createScreen.sh UserVerification UserVerificationSessionsStatus
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

protocol UserVerificationSessionsStatusViewModelViewDelegate: AnyObject {
    func userVerificationSessionsStatusViewModel(_ viewModel: UserVerificationSessionsStatusViewModelType, didUpdateViewState viewSate: UserVerificationSessionsStatusViewState)
}

protocol UserVerificationSessionsStatusViewModelCoordinatorDelegate: AnyObject {
    func userVerificationSessionsStatusViewModel(_ viewModel: UserVerificationSessionsStatusViewModelType, didSelectDeviceWithId deviceId: String, for userId: String)
    func userVerificationSessionsStatusViewModelDidClose(_ viewModel: UserVerificationSessionsStatusViewModelType)
}

/// Protocol describing the view model used by `UserVerificationSessionsStatusViewController`
protocol UserVerificationSessionsStatusViewModelType {
            
    var viewDelegate: UserVerificationSessionsStatusViewModelViewDelegate? { get set }
    var coordinatorDelegate: UserVerificationSessionsStatusViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: UserVerificationSessionsStatusViewAction)
}
