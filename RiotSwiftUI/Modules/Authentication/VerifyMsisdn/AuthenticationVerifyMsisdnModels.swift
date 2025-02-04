//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

// MARK: View model

enum AuthenticationVerifyMsisdnViewModelResult {
    /// Send an SMS to the associated phone number and country code.
    case send(String)
    /// Submit the OTP
    case submitOTP(String)
    /// Send the email once more.
    case resend
    /// Cancel the flow.
    case cancel
    /// Go back to the msisdn form
    case goBack
}

// MARK: View

struct AuthenticationVerifyMsisdnViewState: BindableState {
    /// The homeserver requesting MSISDN verification.
    let homeserver: AuthenticationHomeserverViewData
    /// An SMS has been sent.
    var hasSentSMS = false
    /// View state that can be bound to from SwiftUI.
    var bindings: AuthenticationVerifyMsisdnBindings
    
    /// The message shown in the header while asking for a phone number to be entered.
    var formHeaderMessage: String {
        VectorL10n.authenticationVerifyMsisdnInputMessage(homeserver.address)
    }
    
    /// Whether the phone number is valid and the user can continue.
    var hasInvalidPhoneNumber: Bool {
        bindings.phoneNumber.isEmpty
    }

    /// Whether the OTP is valid and the user can continue.
    var hasInvalidOTP: Bool {
        bindings.otp.isEmpty
    }
}

struct AuthenticationVerifyMsisdnBindings {
    /// The phone number input by the user.
    var phoneNumber: String
    /// The OTP
    var otp: String
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<AuthenticationVerifyMsisdnErrorType>?
}

enum AuthenticationVerifyMsisdnViewAction {
    /// Send an SMS to the entered phone number.
    case send
    /// Submit OTP to verify phone number
    case submitOTP
    /// Send the SMS once more.
    case resend
    /// Cancel the flow.
    case cancel
    /// Go back to msisdn form
    case goBack
}

enum AuthenticationVerifyMsisdnErrorType: Hashable {
    /// An error response from the homeserver.
    case mxError(String)
    /// User entered an invalid phone number
    case invalidPhoneNumber
    /// An unknown error occurred.
    case unknown
}
