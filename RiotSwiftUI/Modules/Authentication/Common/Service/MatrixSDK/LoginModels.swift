//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// The result returned when querying a homeserver's available login flows.
struct LoginFlowResult {
    let supportedLoginTypes: [MXLoginFlow]
    let ssoIdentityProviders: [SSOIdentityProvider]
    let homeserverAddress: String
    let providesDelegatedOIDCCompatibility: Bool
    
    var loginMode: LoginMode {
        if supportedLoginTypes.contains(where: { $0.type == kMXLoginFlowTypeSSO }),
           supportedLoginTypes.contains(where: { $0.type == kMXLoginFlowTypePassword }),
           !providesDelegatedOIDCCompatibility {
            return .ssoAndPassword(ssoIdentityProviders: ssoIdentityProviders)
        } else if supportedLoginTypes.contains(where: { $0.type == kMXLoginFlowTypeSSO }) {
            return .sso(ssoIdentityProviders: ssoIdentityProviders, providesDelegatedOIDCCompatibility: providesDelegatedOIDCCompatibility)
        } else if supportedLoginTypes.contains(where: { $0.type == kMXLoginFlowTypePassword }) {
            return .password
        } else {
            return .unsupported
        }
    }
}

/// The supported forms of login that a homeserver allows.
enum LoginMode {
    /// The login mode hasn't been determined yet.
    case unknown
    /// The homeserver supports login with a password.
    case password
    /// The homeserver supports login via one or more SSO providers.
    case sso(ssoIdentityProviders: [SSOIdentityProvider], providesDelegatedOIDCCompatibility: Bool)
    /// The homeserver supports login with either a password or via an SSO provider.
    case ssoAndPassword(ssoIdentityProviders: [SSOIdentityProvider])
    /// The homeserver only allows login with unsupported mechanisms. Use fallback instead.
    case unsupported
    
    var ssoIdentityProviders: [SSOIdentityProvider]? {
        switch self {
        case .sso(let ssoIdentityProviders, _), .ssoAndPassword(let ssoIdentityProviders):
            // Provide a backup for homeservers that support SSO but don't offer any identity providers
            // https://spec.matrix.org/latest/client-server-api/#client-login-via-sso
            return ssoIdentityProviders.count > 0 ? ssoIdentityProviders : [SSOIdentityProvider(id: "", name: "SSO", brand: nil, iconURL: nil)]
        default:
            return nil
        }
    }
    
    var hasSSO: Bool {
        switch self {
        case .sso, .ssoAndPassword:
            return true
        default:
            return false
        }
    }
    
    var providesDelegatedOIDCCompatibility: Bool {
        switch self {
        case .sso(_, providesDelegatedOIDCCompatibility: true):
            return true
        default:
            return false
        }
    }
    
    var supportsPasswordFlow: Bool {
        switch self {
        case .password, .ssoAndPassword:
            return true
        case .unknown, .unsupported, .sso:
            return false
        }
    }

    var isUnsupported: Bool {
        switch self {
        case .unsupported:
            return true
        default:
            return false
        }
    }
}

/// Data obtained when calling `LoginWizard.resetPassword` that will be used
/// when calling `LoginWizard.checkResetPasswordMailConfirmed`.
struct ResetPasswordData {
    let addThreePIDSessionID: String
}
