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
struct UserSessionInfo: Identifiable {
    /// The session identifier
    let id: String

    /// The session display name
    let name: String?
    
    /// The device type used by the session
    let deviceType: DeviceType
    
    /// True to indicate that the session is verified
    let isVerified: Bool
    
    /// The IP address where this device was last seen.
    let lastSeenIP: String?
    
    /// Last time the session was active
    let lastSeenTimestamp: TimeInterval?

    // MARK: - Application Properties

    /// Application name used by the session
    let applicationName: String?

    /// Application version used by the session
    let applicationVersion: String?

    /// Application URL used by the session. Only applicable for web sessions.
    let applicationURL: String?

    // MARK: - Device Properties

    /// Device model
    let deviceModel: String?

    /// Device OS
    let deviceOS: String?

    /// Last seen IP location
    let lastSeenIPLocation: String?

    /// Client name
    let clientName: String?

    /// Client version
    let clientVersion: String?

    /// True to indicate that session has been used under `inactiveSessionDurationTreshold` value
    let isActive: Bool

    /// True to indicate that this is current user session
    let isCurrent: Bool
}

extension UserSessionInfo: Equatable {
    static func == (lhs: UserSessionInfo, rhs: UserSessionInfo) -> Bool {
        lhs.id == rhs.id
    }
}
