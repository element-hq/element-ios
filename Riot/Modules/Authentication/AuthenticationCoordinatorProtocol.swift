// File created from ScreenTemplate
// $ createScreen.sh Onboarding Authentication
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
