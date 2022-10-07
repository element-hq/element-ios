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
enum MockAuthenticationQRLoginScanScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case scanning
    case noCameraAvailable
    case noCameraAccess
    case noCameraAvailableNoDisplayQR
    case noCameraAccessNoDisplayQR
    
    /// The associated screen
    var screenType: Any.Type {
        AuthenticationQRLoginScanScreen.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockAuthenticationQRLoginScanScreenState] {
        // Each of the presence statuses
        [.scanning, .noCameraAvailable, .noCameraAccess, .noCameraAvailableNoDisplayQR, .noCameraAccessNoDisplayQR]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let service: QRLoginServiceProtocol

        switch self {
        case .scanning:
            service = MockQRLoginService(withState: .scanningQR)
        case .noCameraAvailable:
            service = MockQRLoginService(withState: .failed(error: .noCameraAvailable))
        case .noCameraAccess:
            service = MockQRLoginService(withState: .failed(error: .noCameraAccess))
        case .noCameraAvailableNoDisplayQR:
            service = MockQRLoginService(withState: .failed(error: .noCameraAvailable), canDisplayQR: false)
        case .noCameraAccessNoDisplayQR:
            service = MockQRLoginService(withState: .failed(error: .noCameraAccess), canDisplayQR: false)
        }

        let viewModel = AuthenticationQRLoginScanViewModel(qrLoginService: service)
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [self, viewModel],
            AnyView(AuthenticationQRLoginScanScreen(context: viewModel.context))
        )
    }
}
