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
enum MockAuthenticationSoftLogoutScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case emptyPassword
    case enteredPassword
    case ssoOnly
    case noSSO
    case fallback
    case noKeyBackup
    
    /// The associated screen
    var screenType: Any.Type {
        AuthenticationSoftLogoutScreen.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView)  {
        let viewModel: AuthenticationSoftLogoutViewModel
        let credentials = SoftLogoutCredentials(userId: "@mock:matrix.org",
                                                homeserverName: "matrix.org",
                                                userDisplayName: "mock",
                                                deviceId: nil)
        switch self {
        case .emptyPassword:
            viewModel = AuthenticationSoftLogoutViewModel(credentials: credentials,
                                                          homeserver: .mockMatrixDotOrg,
                                                          keyBackupNeeded: true)
        case .enteredPassword:
            viewModel = AuthenticationSoftLogoutViewModel(credentials: credentials,
                                                          homeserver: .mockMatrixDotOrg,
                                                          keyBackupNeeded: true,
                                                          password: "12345678")
        case .ssoOnly:
            viewModel = AuthenticationSoftLogoutViewModel(credentials: credentials,
                                                          homeserver: .mockEnterpriseSSO,
                                                          keyBackupNeeded: true)
        case .noSSO:
            viewModel = AuthenticationSoftLogoutViewModel(credentials: credentials,
                                                          homeserver: .mockBasicServer,
                                                          keyBackupNeeded: true)
        case .fallback:
            viewModel = AuthenticationSoftLogoutViewModel(credentials: credentials,
                                                          homeserver: .mockFallback,
                                                          keyBackupNeeded: true)
        case .noKeyBackup:
            viewModel = AuthenticationSoftLogoutViewModel(credentials: credentials,
                                                          homeserver: .mockFallback,
                                                          keyBackupNeeded: false)
        }
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [viewModel], AnyView(AuthenticationSoftLogoutScreen(viewModel: viewModel.context))
        )
    }
}
