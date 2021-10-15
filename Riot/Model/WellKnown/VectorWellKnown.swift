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

// MARK: - Well Known

/// `VectorWellKnown` represents additional Well Known configuration specific to Element client
struct VectorWellKnown {
    let encryption: VectorWellKnownEncryptionConfiguration?
    let jitsi: VectorWellKnownJitsiConfiguration?
    
    // Deprecated properties
    let deprecatedEncryption: VectorWellKnownEncryptionConfiguration?
    let deprecatedJitsi: VectorWellKnownJitsiConfiguration?
}

// MARK: Decodable
extension VectorWellKnown: Decodable {
    /// JSON keys associated to VectorWellKnown properties
    enum CodingKeys: String, CodingKey {
        case encryption = "io.element.e2ee"
        case jitsi = "io.element.jitsi"
        // Deprecated keys
        case deprecatedEncryption = "im.vector.riot.e2ee"
        case deprecatedJitsi = "im.vector.riot.jitsi"
    }
}

// MARK: - Encryption

struct VectorWellKnownEncryptionConfiguration: Decodable {
    
    /// Indicate if E2EE is enabled by default
    let isE2EEByDefaultEnabled: Bool?
    
    enum CodingKeys: String, CodingKey {
        case isE2EEByDefaultEnabled = "default"
    }
}

// MARK: - Jitsi
struct VectorWellKnownJitsiConfiguration: Decodable {
    
    /// Default Jitsi server
    let preferredDomain: String?
}
