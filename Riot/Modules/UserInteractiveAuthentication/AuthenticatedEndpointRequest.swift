// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
