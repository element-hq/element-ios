// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// `JitsiWellKnown` represents configuration specific to a Jitsi domain.
/// See https://github.com/matrix-org/prosody-mod-auth-matrix-user-verification#jitsi-auth-well-known
struct JitsiWellKnown {
    let authenticationType: JitsiAuthenticationType?
}

// MARK: Decodable
extension JitsiWellKnown: Decodable {
    /// JSON keys associated to VectorWellKnown properties
    enum CodingKeys: String, CodingKey {
        case authenticationType = "auth"
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let authenticationTypeString = try container.decodeIfPresent(String.self, forKey: .authenticationType) {
            self.authenticationType = JitsiAuthenticationType(authenticationTypeString)
        } else {
            self.authenticationType = nil
        }
    }
}
