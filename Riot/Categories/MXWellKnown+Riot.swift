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

extension MXWellKnown {
    
    // MARK: - Public
    
    /// Check if a default Jitsi server has been set on the homeserver.
    ///
    /// HS admins can set this value in /.well-known/matrix/client:
    /// "im.vector.riot.jitsi": {
    ///   "preferredDomain": "your.jitsi.example.org"
    /// }
    @objc func vc_jitsiPreferredDomain() -> String? {
        let jitsiConfiguration = self.vc_getJitsiConfiguration()
        return jitsiConfiguration?.preferredDomain
    }
    
    /// Convenient method that returns Jitsi server URL based on Jitsi preferred domain.
    /// Note: `https` scheme is forced when there is no URL scheme.
    @objc func vc_jitsiPreferredServerURL() -> URL? {
        guard let jitsiServerDomain = self.vc_jitsiPreferredDomain() else {
            return nil
        }
        
        let jitsiStringURL: String
        if jitsiServerDomain.starts(with: "http") {
            jitsiStringURL = jitsiServerDomain
        } else {
            jitsiStringURL = "https://\(jitsiServerDomain)"
        }
        
        guard let jitsiServerURL = URL(string: jitsiStringURL) else {
            NSLog("[MXWellKnown+Riot] Jitsi server URL is not valid")
            return nil
        }
        
        return jitsiServerURL
    }
    
    /// Check if E2EE by default is welcomed on the user's HS.
    /// The default value is true.
    ///
    /// HS admins can disable it in /.well-known/matrix/client by returning:
    /// "io.element.e2ee": {
    ///  "default": false
    /// }
    @objc func vc_isE2EEByDefaultEnabled() -> Bool {
        let encryptionConfiguration = self.vc_getEncryptionConfiguration()
        return encryptionConfiguration?.isE2EEByDefaultEnabled ?? true
    }
    
    // MARK: - Private
    
    /// Return additional Well Known configuration specific to Element client
    /// Note: Do not expose VectorWellKnown publicly as default values are set in extension methods for the moment.
    private func vc_getVectorWellKnown() -> VectorWellKnown? {
        guard let jsonDictionary = self.jsonDictionary() else {
            return nil
        }
        let serializationService = SerializationService()
        let vectorWellKnown: VectorWellKnown?
                        
        do {
            vectorWellKnown = try serializationService.deserialize(jsonDictionary)
        } catch {
            vectorWellKnown = nil
            NSLog("[MXWellKnown+Riot] Fail to parse application Well Known keys with error: \(error)")
        }
        
        return vectorWellKnown
    }
    
    private func vc_getJitsiConfiguration() -> VectorWellKnownJitsiConfiguration? {
        guard let wellKnown = self.vc_getVectorWellKnown() else {
            return nil
        }
        
        let jitsiConfiguration: VectorWellKnownJitsiConfiguration?
        
        if let lastJitsiConfiguration = wellKnown.jitsi {
            jitsiConfiguration = lastJitsiConfiguration
        } else if let deprecatedJitsiConfiguration = wellKnown.deprecatedJitsi {
            NSLog("[MXWellKnown+Riot] getJitsiConfiguration - Use deprecated configuration")
            jitsiConfiguration = deprecatedJitsiConfiguration
        } else {
            NSLog("[MXWellKnown+Riot] getJitsiConfiguration - No configuration found")
            jitsiConfiguration = nil
        }
        
        return jitsiConfiguration
    }
    
    private func vc_getEncryptionConfiguration() -> VectorWellKnownEncryptionConfiguration? {
        guard let wellKnown = self.vc_getVectorWellKnown() else {
            return nil
        }
        
        let encryptionConfiguration: VectorWellKnownEncryptionConfiguration?
        
        if let lastEncryptionConfiguration = wellKnown.encryption {
            encryptionConfiguration = lastEncryptionConfiguration
        } else if let deprecatedJitsiConfiguration = wellKnown.deprecatedEncryption {
            NSLog("[MXWellKnown+Riot] getEncryptionConfiguration - Use deprecated configuration")
            encryptionConfiguration = deprecatedJitsiConfiguration
        } else {
            NSLog("[MXWellKnown+Riot] getEncryptionConfiguration - No configuration found")
            encryptionConfiguration = nil
        }
        
        return encryptionConfiguration
    }
}
