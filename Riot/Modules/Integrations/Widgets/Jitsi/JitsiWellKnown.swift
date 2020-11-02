// 
// Copyright 2020 New Vector Ltd
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
