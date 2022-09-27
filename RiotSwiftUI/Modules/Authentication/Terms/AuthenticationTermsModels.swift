//
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
