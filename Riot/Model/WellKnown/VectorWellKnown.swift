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
struct VectorWellKnownEncryptionConfiguration {
    /// Indicate if E2EE is enabled by default
    let isE2EEByDefaultEnabled: Bool?
    /// Check if secure backup (SSSS) is mandatory.
    let isSecureBackupRequired: Bool?
    /// Methods to use to setup secure backup (SSSS).
    let secureBackupSetupMethods: [VectorWellKnownBackupSetupMethod]?
    /// Outbound keys pre sharing strategy.
    let outboundKeysPreSharingMode: MXKKeyPreSharingStrategy?
}

extension VectorWellKnownEncryptionConfiguration: Decodable {
    /// JSON keys associated to `VectorWellKnownEncryptionConfiguration`
    enum CodingKeys: String, CodingKey {
        case isE2EEByDefaultEnabled = "default"
        case isSecureBackupRequired = "secure_backup_required"
        case secureBackupSetupMethods = "secure_backup_setup_methods"
        case outboundKeysPreSharingMode = "outbound_keys_pre_sharing_mode"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isE2EEByDefaultEnabled = try? container.decode(Bool.self, forKey: .isE2EEByDefaultEnabled)
        isSecureBackupRequired = try? container.decode(Bool.self, forKey: .isSecureBackupRequired)
        let secureBackupSetupMethodsKeys = try? container.decode([String].self, forKey: .secureBackupSetupMethods)
        secureBackupSetupMethods = secureBackupSetupMethodsKeys?.compactMap { VectorWellKnownBackupSetupMethod(key: $0) }
        let outboundKeysPreSharingModeKey = try? container.decode(String.self, forKey: .outboundKeysPreSharingMode)
        outboundKeysPreSharingMode = MXKKeyPreSharingStrategy(key: outboundKeysPreSharingModeKey)
    }
}

// MARK: - Jitsi
struct VectorWellKnownJitsiConfiguration: Decodable {
    
    /// Default Jitsi server
    let preferredDomain: String?
}
