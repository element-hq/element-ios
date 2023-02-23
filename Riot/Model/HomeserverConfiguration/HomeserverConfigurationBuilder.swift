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

/// `HomeserverConfigurationBuilder` build `HomeserverConfiguration` objects according to injected inputs
@objcMembers
final class HomeserverConfigurationBuilder: NSObject {

    // MARK: - Properties
    
    private let vectorWellKnownParser = VectorWellKnownParser()
    
    // MARK: - Public
    
    /// Create an `HomeserverConfiguration` from an HS Well-Known when possible otherwise it takes hardcoded values from BuildSettings by default.
    func build(from wellKnown: MXWellKnown?) -> HomeserverConfiguration {
        var vectorWellKnownEncryptionConfiguration: VectorWellKnownEncryptionConfiguration?
        var vectorWellKnownJitsiConfiguration: VectorWellKnownJitsiConfiguration?
        
        if let wellKnown = wellKnown, let vectorWellKnown = self.vectorWellKnownParser.parse(jsonDictionary: wellKnown.jsonDictionary()) {
            vectorWellKnownEncryptionConfiguration = self.getEncryptionConfiguration(from: vectorWellKnown)
            vectorWellKnownJitsiConfiguration = self.getJitsiConfiguration(from: vectorWellKnown)
        }

        // Encryption configuration
        // Enable E2EE by default when there is no value
        let isE2EEByDefaultEnabled = vectorWellKnownEncryptionConfiguration?.isE2EEByDefaultEnabled ?? true
        // Disable mandatory secure backup when there is no value
        let isSecureBackupRequired = vectorWellKnownEncryptionConfiguration?.isSecureBackupRequired ?? false
        // Default to `MXKKeyPreSharingWhenTyping` when there is no value
        let outboundKeysPreSharingMode = vectorWellKnownEncryptionConfiguration?.outboundKeysPreSharingMode ?? .whenTyping
        // Defaults to all secure backup methods available when there is no value
        let secureBackupSetupMethods: [VectorWellKnownBackupSetupMethod]
        if let backupSetupMethods = vectorWellKnownEncryptionConfiguration?.secureBackupSetupMethods {
            secureBackupSetupMethods = backupSetupMethods.isEmpty ? VectorWellKnownBackupSetupMethod.allCases : backupSetupMethods
        } else {
            secureBackupSetupMethods = VectorWellKnownBackupSetupMethod.allCases
        }

        let encryptionConfiguration = HomeserverEncryptionConfiguration(isE2EEByDefaultEnabled: isE2EEByDefaultEnabled,
                                                                        isSecureBackupRequired: isSecureBackupRequired,
                                                                        secureBackupSetupMethods: secureBackupSetupMethods,
                                                                        outboundKeysPreSharingMode: outboundKeysPreSharingMode)
        
        // Jitsi configuration
        let jitsiPreferredDomain: String?
        let jitsiServerURL: URL?
        let hardcodedJitsiServerURL: URL? = BuildSettings.jitsiServerUrl
        
        if let preferredDomain = vectorWellKnownJitsiConfiguration?.preferredDomain {
            jitsiPreferredDomain = preferredDomain
            jitsiServerURL = self.jitsiServerURL(from: preferredDomain) ?? hardcodedJitsiServerURL
        } else {
            jitsiPreferredDomain = hardcodedJitsiServerURL?.host
            jitsiServerURL = hardcodedJitsiServerURL
        }
        
        // Tile server configuration
        
        let tileServerMapStyleURL: URL
        if let mapStyleURLString = wellKnown?.tileServer?.mapStyleURLString,
           let mapStyleURL = URL(string: mapStyleURLString) {
            tileServerMapStyleURL = mapStyleURL
        } else {
            tileServerMapStyleURL = BuildSettings.defaultTileServerMapStyleURL
        }
        
        let tileServerConfiguration = HomeserverTileServerConfiguration(mapStyleURL: tileServerMapStyleURL)
        
        // Create HomeserverConfiguration
        
        let jitsiConfiguration = HomeserverJitsiConfiguration(serverDomain: jitsiPreferredDomain,
                                                              serverURL: jitsiServerURL)
                
        return HomeserverConfiguration(jitsi: jitsiConfiguration,
                                       encryption: encryptionConfiguration,
                                       tileServer: tileServerConfiguration)
    }
    
    // MARK: - Private
    
    private func getJitsiConfiguration(from vectorWellKnown: VectorWellKnown) -> VectorWellKnownJitsiConfiguration? {
                
        let jitsiConfiguration: VectorWellKnownJitsiConfiguration?
        
        if let lastJitsiConfiguration = vectorWellKnown.jitsi {
            jitsiConfiguration = lastJitsiConfiguration
        } else if let deprecatedJitsiConfiguration = vectorWellKnown.deprecatedJitsi {
            MXLog.debug("[HomeserverConfigurationBuilder] getJitsiConfiguration - Use deprecated configuration")
            jitsiConfiguration = deprecatedJitsiConfiguration
        } else {
            MXLog.debug("[HomeserverConfigurationBuilder] getJitsiConfiguration - No configuration found")
            jitsiConfiguration = nil
        }
        
        return jitsiConfiguration
    }
    
    private func getEncryptionConfiguration(from vectorWellKnown: VectorWellKnown) -> VectorWellKnownEncryptionConfiguration? {
        
        let encryptionConfiguration: VectorWellKnownEncryptionConfiguration?
        
        if let lastEncryptionConfiguration = vectorWellKnown.encryption {
            encryptionConfiguration = lastEncryptionConfiguration
        } else if let deprecatedEncryptionConfiguration = vectorWellKnown.deprecatedEncryption {
            MXLog.debug("[HomeserverConfigurationBuilder] getEncryptionConfiguration - Use deprecated configuration")
            encryptionConfiguration = deprecatedEncryptionConfiguration
        } else {
            MXLog.debug("[HomeserverConfigurationBuilder] getEncryptionConfiguration - No configuration found")
            encryptionConfiguration = nil
        }
        
        return encryptionConfiguration
    }
    
    private func jitsiServerURL(from jitsiServerDomain: String) -> URL? {
        let jitsiStringURL: String
        if jitsiServerDomain.starts(with: "http") {
            jitsiStringURL = jitsiServerDomain
        } else {
            jitsiStringURL = "https://\(jitsiServerDomain)"
        }
        
        guard let jitsiServerURL = URL(string: jitsiStringURL) else {
            MXLog.debug("[HomeserverConfigurationBuilder] Jitsi server URL is not valid")
            return nil
        }
        
        return jitsiServerURL
    }
}
