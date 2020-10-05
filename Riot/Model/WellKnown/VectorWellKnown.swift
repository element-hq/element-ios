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

/// `VectorWellKnown` represents additional Well Known configuration specific to Element client
struct VectorWellKnown: Codable {
    let encryption: VectorWellKnownEncryptionConfiguration?
    let jitsi: VectorWellKnownJitsiConfiguration?
    
    enum CodingKeys: String, CodingKey {
        case jitsi = "im.vector.riot.jitsi"
        case encryption = "im.vector.riot.e2ee"
    }
}

// MARK: - Encryption

struct VectorWellKnownEncryptionConfiguration: Codable {
    
    /// Indicate if E2EE is enabled by default
    let isE2EEByDefaultEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case isE2EEByDefaultEnabled = "default"
    }
}

// MARK: - Jitsi
struct VectorWellKnownJitsiConfiguration: Codable {
    
    /// Default Jitsi server
    let preferredDomain: String
}
