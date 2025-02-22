//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// The parameters used for registration requests.
struct RegistrationParameters: DictionaryEncodable, Equatable {
    /// Authentication parameters
    var auth: AuthenticationParameters?
    
    /// The account username
    var username: String?
    
    /// The account password
    var password: String?
    
    /// Device name
    var initialDeviceDisplayName: String?
    
    /// Temporary flag to notify the server that we support MSISDN flow. Used to prevent old app
    /// versions to end up in fallback because the HS returns the MSISDN flow which they don't support
    var xShowMSISDN: Bool?
    
    enum CodingKeys: String, CodingKey {
        case auth
        case username
        case password
        case initialDeviceDisplayName = "initial_device_display_name"
        case xShowMSISDN = "x_show_msisdn"
    }
}

/// The data passed to the `auth` parameter in authentication requests.
struct AuthenticationParameters: Encodable, Equatable {
    /// The type of authentication taking place. The identifier from `MXLoginFlowType`.
    let type: String
    
    /// Note: session can be null for reset password request
    var session: String?
    
    /// parameter for "m.login.recaptcha" type
    var captchaResponse: String?
    
    /// parameter for "m.login.email.identity" type
    var threePIDCredentials: ThreePIDCredentials?
    
    enum CodingKeys: String, CodingKey {
        case type
        case session
        case captchaResponse = "response"
        case threePIDCredentials = "threepid_creds"
    }
    
    /// Creates the authentication parameters for a captcha step.
    static func captchaParameters(session: String, captchaResponse: String) -> AuthenticationParameters {
        AuthenticationParameters(type: kMXLoginFlowTypeRecaptcha, session: session, captchaResponse: captchaResponse)
    }
    
    /// Creates the authentication parameters for a third party ID step using an email address.
    static func emailIdentityParameters(session: String, threePIDCredentials: ThreePIDCredentials) -> AuthenticationParameters {
        AuthenticationParameters(type: kMXLoginFlowTypeEmailIdentity, session: session, threePIDCredentials: threePIDCredentials)
    }
    
    // Note that there is a bug in Synapse (needs investigation), but if we pass .msisdn,
    // the homeserver answer with the login flow with MatrixError fields and not with a simple MatrixError 401.
    /// Creates the authentication parameters for a third party ID step using a phone number.
    static func msisdnIdentityParameters(session: String, threePIDCredentials: ThreePIDCredentials) -> AuthenticationParameters {
        AuthenticationParameters(type: kMXLoginFlowTypeMSISDN, session: session, threePIDCredentials: threePIDCredentials)
    }
    
    /// Creates the authentication parameters for a password reset step.
    static func resetPasswordParameters(clientSecret: String, sessionID: String) -> AuthenticationParameters {
        AuthenticationParameters(type: kMXLoginFlowTypeEmailIdentity,
                                 session: nil,
                                 threePIDCredentials: ThreePIDCredentials(clientSecret: clientSecret, sessionID: sessionID))
    }
}
