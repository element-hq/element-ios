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
enum MockAuthenticationTermsScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case matrixDotOrg
    case accepted
    case multiple
    
    /// The associated screen
    var screenType: Any.Type {
        AuthenticationTermsScreen.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView)  {
        let viewModel: AuthenticationTermsViewModel
        switch self {
        case .matrixDotOrg:
            viewModel = AuthenticationTermsViewModel(homeserver: .mockMatrixDotOrg,
                                                     policies: [AuthenticationTermsPolicy(url: "https://matrix-client.matrix.org/_matrix/consent?v=1.0",
                                                                                          title: "Terms and Conditions",
                                                                                          subtitle: "matrix.org")])
        case .accepted:
            viewModel = AuthenticationTermsViewModel(homeserver: .mockMatrixDotOrg,
                                                     policies: [AuthenticationTermsPolicy(url: "https://matrix-client.matrix.org/_matrix/consent?v=1.0",
                                                                                          title: "Terms and Conditions",
                                                                                          subtitle: "matrix.org",
                                                                                          accepted: true)])
        case .multiple:
            viewModel = AuthenticationTermsViewModel(homeserver: .mockBasicServer, policies: [
                AuthenticationTermsPolicy(url: "https://example.com/terms", title: "Terms and Conditions", subtitle: "example.com"),
                AuthenticationTermsPolicy(url: "https://example.com/privacy", title: "Privacy Policy", subtitle: "example.com"),
                AuthenticationTermsPolicy(url: "https://example.com/conduct", title: "Code of Conduct", subtitle: "example.com")
            ])
        }
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [viewModel], AnyView(AuthenticationTermsScreen(viewModel: viewModel.context))
        )
    }
}
