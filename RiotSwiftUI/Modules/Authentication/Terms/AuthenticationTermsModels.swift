//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Coordinator

struct AuthenticationTermsPolicy: Identifiable, Equatable {
    var id: String { url }
    /// The URL that can be used to view the policy.
    let url: String
    /// The policy's title.
    let title: String
    /// The policy's subtitle.
    let subtitle: String
    /// Whether or not the policy has been accepted.
    var accepted = false
}

// MARK: View model

enum AuthenticationTermsViewModelResult {
    /// Continue on to the next step in the flow.
    case next
    /// Show the selected policy.
    case showPolicy(AuthenticationTermsPolicy)
    /// Cancel the flow.
    case cancel
}

// MARK: View

struct AuthenticationTermsViewState: BindableState {
    /// The homeserver asking the user to accept the terms.
    let homeserver: AuthenticationHomeserverViewData
    /// View state that can be bound to from SwiftUI.
    var bindings: AuthenticationTermsBindings
    
    var headerMessage: String {
        VectorL10n.authenticationTermsMessage(homeserver.address)
    }
    
    /// Whether or not all of the policies have been accepted.
    var hasAcceptedAllPolicies: Bool {
        bindings.policies.allSatisfy(\.accepted)
    }
}

struct AuthenticationTermsBindings {
    /// All of the policies that need to be accepted.
    var policies: [AuthenticationTermsPolicy]
    /// Information about the currently displayed alert.
    var alertInfo: AlertInfo<AuthenticationTermsErrorType>?
}

enum AuthenticationTermsViewAction {
    /// Continue on to the next step in the flow.
    case next
    /// Show the selected policy.
    case showPolicy(AuthenticationTermsPolicy)
    /// Cancel the flow.
    case cancel
}

enum AuthenticationTermsErrorType: Hashable {
    /// An error response from the homeserver.
    case mxError(String)
    /// The homeserver supplied an invalid URL for the policy.
    case invalidPolicyURL
    /// An unknown error occurred.
    case unknown
}
