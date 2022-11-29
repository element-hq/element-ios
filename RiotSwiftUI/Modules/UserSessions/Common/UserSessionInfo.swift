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
    
    /// The current state of verification for the session.
    let verificationState: VerificationState
    
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
    
    /// Represents a verification state.
    enum VerificationState {
        /// The state is unknown (likely because the current session
        /// hasn't been set up for cross-signing yet).
        case unknown
        /// The session has not yet been verified.
        case unverified
        /// The session has been verified.
        case verified
        /// A session which cannot be never verified due to lack of crypto support
        case permanentlyUnverified
        
        var isUnverified: Bool {
            self == .unverified || self == .permanentlyUnverified
        }
    }
}

// MARK: - Equatable

extension UserSessionInfo: Equatable {
    static func == (lhs: UserSessionInfo, rhs: UserSessionInfo) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Mocks

extension UserSessionInfo {
    static func mockPhone(verificationState: VerificationState = .verified,
                          hasTimestamp: Bool = true,
                          isCurrent: Bool = false) -> UserSessionInfo {
        UserSessionInfo(id: "1",
                        name: "Element Mobile: iOS",
                        deviceType: .mobile,
                        verificationState: verificationState,
                        lastSeenIP: "1.0.0.1",
                        lastSeenTimestamp: hasTimestamp ? Date().timeIntervalSince1970 : nil,
                        applicationName: "Element iOS",
                        applicationVersion: "1.9.8",
                        applicationURL: nil,
                        deviceModel: nil,
                        deviceOS: "iOS 16.0.2",
                        lastSeenIPLocation: nil,
                        clientName: nil,
                        clientVersion: nil,
                        isActive: true,
                        isCurrent: isCurrent)
    }
}
