// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// `JitsiAuthenticationType` represents authentification type supported by a Jitsi server
/// See https://github.com/matrix-org/prosody-mod-auth-matrix-user-verification
enum JitsiAuthenticationType: Equatable {
    case openIDTokenJWT
    case other(String)
            
    private enum KnownAuthenticationType: String {
        case openIDTokenJWT = "openidtoken-jwt"
    }
    
    var identifier: String {
        switch self {
        case .openIDTokenJWT:
            return KnownAuthenticationType.openIDTokenJWT.rawValue
        case .other(let authentificationString):
            return authentificationString
        }
    }
}

extension JitsiAuthenticationType {
    init(_ value: String) {
        switch value {
        case KnownAuthenticationType.openIDTokenJWT.rawValue:
            self = .openIDTokenJWT
        default:
            self = .other(value)
        }
    }
}
