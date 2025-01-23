//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    var screenView: ([Any], AnyView) {
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
