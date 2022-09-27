// 
// Copyright 2022 New Vector Ltd
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

/// Represents a user session information
struct UserSessionInfo {
        
    /// Delay after which session is considered inactive, 90 days
    static let inactiveSessionDurationTreshold: TimeInterval = 90 * 86400
    
    // MARK: - Properties

    /// The session identifier
    let sessionId: String

    /// The session display name
    let sessionName: String?
    
    /// The device type used by the session
    let deviceType: DeviceType
    
    /// True to indicate that the session is verified
    let isVerified: Bool
    
    /// The IP address where this device was last seen.
    let lastSeenIP: String?
    
    /// Last time the session was active
    let lastSeenTimestamp: TimeInterval?

    /// Application name used by the session
    let applicationName: String?

    /// Application version used by the session
    let applicationVersion: String?

    /// Application URL used by the session. Only applicable for web sessions.
    let applicationURL: String?
}

extension UserSessionInfo: Identifiable {
    var id: String {
        return sessionId
    }
}

extension UserSessionInfo {
    /// True to indicate that session has been used under `inactiveSessionDurationTreshold` value
    var isSessionActive: Bool {
        guard let lastSeenTimestamp = lastSeenTimestamp else {
            return true
        }

        let elapsedTime = Date().timeIntervalSince1970 - lastSeenTimestamp
        return elapsedTime < Self.inactiveSessionDurationTreshold
    }
}
