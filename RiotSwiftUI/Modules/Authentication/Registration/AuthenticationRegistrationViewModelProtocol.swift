//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol AuthenticationRegistrationViewModelProtocol {
    var callback: (@MainActor (AuthenticationRegistrationViewModelResult) -> Void)? { get set }
    var context: AuthenticationRegistrationViewModelType.Context { get }
    
    /// Update the view to reflect that a new homeserver is being loaded.
    /// - Parameter isLoading: Whether or not the homeserver is being loaded.
    @MainActor func update(isLoading: Bool)
    
    /// Update the view with new homeserver information.
    /// - Parameter homeserver: The view data for the homeserver. This can be generated using `AuthenticationService.Homeserver.viewData`.
    @MainActor func update(homeserver: AuthenticationHomeserverViewData)
    
    /// Update the username, for example to convert a full MXID into just the local part.
    /// - Parameter username: The username to be shown instead.
    @MainActor func update(username: String)
    
    /// Update the view to confirm that the chosen username is available.
    /// - Parameter username: The username that was checked.
    @MainActor func confirmUsernameAvailability(_ username: String)
    
    /// Display an error to the user.
    /// - Parameter type: The type of error to be displayed.
    @MainActor func displayError(_ type: AuthenticationRegistrationErrorType)
}
