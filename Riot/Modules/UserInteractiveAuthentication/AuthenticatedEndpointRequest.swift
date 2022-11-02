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

/// AuthenticatedEndpointRequest represents authenticated API endpoint request.
@objcMembers
class AuthenticatedEndpointRequest: NSObject {
    
    let path: String
    let httpMethod: String
    let params: [String: Any]
    init(path: String, httpMethod: String, params: [String: Any]) {
        self.path = path
        self.httpMethod = httpMethod
        self.params = params
        super.init()
    }
}

// MARK: - Helper methods

extension AuthenticatedEndpointRequest {
    /// Create an authenticated request on `_matrix/client/r0/devices/{deviceID}`.
    /// - Parameter deviceID: The device ID that is to be deleted.
    static func deleteDevice(_ deviceID: String) -> AuthenticatedEndpointRequest {
        let path = String(format: "%@/devices/%@", kMXAPIPrefixPathR0, MXTools.encodeURIComponent(deviceID))
        return AuthenticatedEndpointRequest(path: path, httpMethod: "DELETE", params: [:])
    }
}

extension AuthenticatedEndpointRequest {
    /// Create an authenticated request on `_matrix/client/r0/delete_devices`.
    /// - Parameter deviceIDs: IDs for devices that is to be deleted.
    static func deleteDevices(_ deviceIDs: [String]) -> AuthenticatedEndpointRequest {
        let path = String(format: "%@/delete_devices", kMXAPIPrefixPathR0)
        return AuthenticatedEndpointRequest(path: path, httpMethod: "POST", params: ["devices": deviceIDs])
    }
}
