//
// Copyright 2022 New Vector Ltd
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

/// The result returned when querying a homeserver's available login flows.
struct LoginFlowResult {
    let supportedLoginTypes: [MXLoginFlow]
    let ssoIdentityProviders: [SSOIdentityProvider]
    let homeserverAddress: String
    
    var loginMode: LoginMode {
        if supportedLoginTypes.contains(where: { $0.type == kMXLoginFlowTypeSSO }),
           supportedLoginTypes.contains(where: { $0.type == kMXLoginFlowTypePassword }) {
            return .ssoAndPassword(ssoIdentityProviders: ssoIdentityProviders)
        } else if supportedLoginTypes.contains(where: { $0.type == kMXLoginFlowTypeSSO }) {
            return .sso(ssoIdentityProviders: ssoIdentityProviders)
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
    case sso(ssoIdentityProviders: [SSOIdentityProvider])
    /// The homeserver supports login with either a password or via an SSO provider.
    case ssoAndPassword(ssoIdentityProviders: [SSOIdentityProvider])
    /// The homeserver only allows login with unsupported mechanisms. Use fallback instead.
    case unsupported
    
    var ssoIdentityProviders: [SSOIdentityProvider]? {
        switch self {
        case .sso(let ssoIdentityProviders), .ssoAndPassword(let ssoIdentityProviders):
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
