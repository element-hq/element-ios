//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockAuthenticationVerifyMsisdnScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case emptyPhoneNumber
    case enteredPhoneNumber
    case hasSentSMS
    case enteredOTP
    
    /// The associated screen
    var screenType: Any.Type {
        AuthenticationVerifyMsisdnScreen.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let viewModel: AuthenticationVerifyMsisdnViewModel
        switch self {
        case .emptyPhoneNumber:
            viewModel = AuthenticationVerifyMsisdnViewModel(homeserver: .mockMatrixDotOrg,
                                                            phoneNumber: "")
        case .enteredPhoneNumber:
            viewModel = AuthenticationVerifyMsisdnViewModel(homeserver: .mockMatrixDotOrg,
                                                            phoneNumber: "+44 XXXXXXXXX")
        case .hasSentSMS:
            viewModel = AuthenticationVerifyMsisdnViewModel(homeserver: .mockMatrixDotOrg,
                                                            phoneNumber: "+44 XXXXXXXXX")
            Task { await viewModel.updateForSentSMS() }
        case .enteredOTP:
            viewModel = AuthenticationVerifyMsisdnViewModel(homeserver: .mockMatrixDotOrg,
                                                            phoneNumber: "+44 XXXXXXXXX",
                                                            otp: "123456")
            Task { await viewModel.updateForSentSMS() }
        }
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [viewModel], AnyView(AuthenticationVerifyMsisdnScreen(viewModel: viewModel.context))
        )
    }
}
