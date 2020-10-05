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
    
    /// Check if a default Jitsi server has been set on the homeserver.
    ///
    /// HS admins can set this value in /.well-known/matrix/client:
    /// "im.vector.riot.jitsi": {
    ///   "preferredDomain": "your.jitsi.example.org"
    /// }
    @objc func vc_jitsiPreferredDomain() -> String? {
        let wellKnown = self.vc_getVectorWellKnown()
        return wellKnown?.jitsi?.preferredDomain
    }
    
    /// Check if E2EE by default is welcomed on the user's HS.
    /// The default value is true.
    ///
    /// HS admins can disable it in /.well-known/matrix/client by returning:
    /// "im.vector.riot.e2ee": {
    ///  "default": false
    /// }
    @objc func vc_isE2EEByDefaultEnabled() -> Bool {
        let wellKnown = self.vc_getVectorWellKnown()
        return wellKnown?.encryption?.isE2EEByDefaultEnabled ?? true
    }
    
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
}
