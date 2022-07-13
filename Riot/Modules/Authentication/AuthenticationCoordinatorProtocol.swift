// File created from ScreenTemplate
// $ createScreen.sh Onboarding Authentication
/*
 Copyright 2021 New Vector Ltd
 
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

enum AuthenticationCoordinatorResult {
    /// The coordinator has started and has presented itself.
    case didStart
    /// The user has authenticated but key verification is yet to happen. The session value is
    /// for a fresh session that still needs to load, sync etc before being ready.
    case didLogin(session: MXSession, authenticationFlow: AuthenticationFlow, authenticationType: AuthenticationType)
    /// All of the required authentication steps including key verification is complete.
    case didComplete
    /// In case of soft logout, user has decided to clear all data
    case clearAllData
    /// The user has cancelled the associated authentication flow.
    case cancel(AuthenticationFlow)
}

/// `AuthenticationCoordinatorProtocol` is a protocol describing a Coordinator that handle's the authentication navigation flow.
protocol AuthenticationCoordinatorProtocol: Coordinator, Presentable {
    var callback: ((AuthenticationCoordinatorResult) -> Void)? { get set }
    
    /// Update the screen to display registration or login.
    func update(authenticationFlow: AuthenticationFlow)

    /// Indicates to the coordinator to display any pending screens if it was created with
    /// the `canPresentAdditionalScreens` parameter set to `false`
    func presentPendingScreensIfNecessary()
}
