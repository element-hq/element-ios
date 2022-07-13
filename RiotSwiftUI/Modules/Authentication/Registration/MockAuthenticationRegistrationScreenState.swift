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
import SwiftUI

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockAuthenticationRegistrationScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case matrixDotOrg
    case passwordOnly
    case passwordWithCredentials
    case passwordWithUsernameError
    case ssoOnly
    case fallback

    /// The associated screen
    var screenType: Any.Type {
        AuthenticationRegistrationScreen.self
    }

    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView)  {
        let viewModel: AuthenticationRegistrationViewModel
        switch self {
        case .matrixDotOrg:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .mockMatrixDotOrg)
        case .passwordOnly:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .mockBasicServer)
        case .passwordWithCredentials:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .mockBasicServer)
            viewModel.context.username = "alice"
            viewModel.context.password = "password"
            Task { await viewModel.confirmUsernameAvailability("alice") }
        case .passwordWithUsernameError:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .mockBasicServer)
            viewModel.state.hasEditedUsername = true
            Task { await viewModel.displayError(.usernameUnavailable(VectorL10n.authInvalidUserName)) }
        case .ssoOnly:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .mockEnterpriseSSO)
        case .fallback:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .mockFallback)
        }
        

        // can simulate service and viewModel actions here if needs be.

        return (
            [viewModel], AnyView(AuthenticationRegistrationScreen(viewModel: viewModel.context))
        )
    }
}
