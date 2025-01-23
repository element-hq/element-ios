//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol AuthenticationLoginViewModelProtocol {
    var callback: (@MainActor (AuthenticationLoginViewModelResult) -> Void)? { get set }
    var context: AuthenticationLoginViewModelType.Context { get }
    
    /// Update the view to reflect that a new homeserver is being loaded.
    /// - Parameter isLoading: Whether or not the homeserver is being loaded.
    @MainActor func update(isLoading: Bool)
    
    /// Update the view with new homeserver information.
    /// - Parameter homeserver: The view data for the homeserver. This can be generated using `AuthenticationService.Homeserver.viewData`.
    @MainActor func update(homeserver: AuthenticationHomeserverViewData)
    
    /// Display an error to the user.
    /// - Parameter type: The type of error to be displayed.
    @MainActor func displayError(_ type: AuthenticationLoginErrorType)
}
