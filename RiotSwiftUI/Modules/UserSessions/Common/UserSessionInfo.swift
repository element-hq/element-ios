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
    
    // MARK: - Session Properties

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

    /// Device name
    let deviceName: String?

    /// True to indicate that this is current user session
    let isCurrentSession: Bool
}

extension UserSessionInfo: Identifiable {
    var id: String {
        sessionId
    }
}

// MARK: - Derived

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

extension UserSessionInfo: Equatable {
    static func == (lhs: UserSessionInfo, rhs: UserSessionInfo) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Mock Data

extension UserSessionInfo {
    static let mockCurrentFull = UserSessionInfo(sessionId: "alice",
                                                 sessionName: "iOS",
                                                 deviceType: .mobile,
                                                 isVerified: false,
                                                 lastSeenIP: "10.0.0.10",
                                                 lastSeenTimestamp: nil,
                                                 applicationName: "Element iOS",
                                                 applicationVersion: "1.0.0",
                                                 applicationURL: nil,
                                                 deviceModel: nil,
                                                 deviceOS: "iOS 15.5",
                                                 lastSeenIPLocation: nil,
                                                 deviceName: "My iPhone",
                                                 isCurrentSession: true)

    static let mockCurrentSessionOnly = UserSessionInfo(sessionId: "alice",
                                                        sessionName: "iOS",
                                                        deviceType: .mobile,
                                                        isVerified: false,
                                                        lastSeenIP: nil,
                                                        lastSeenTimestamp: nil,
                                                        applicationName: nil,
                                                        applicationVersion: nil,
                                                        applicationURL: nil,
                                                        deviceModel: nil,
                                                        deviceOS: nil,
                                                        lastSeenIPLocation: nil,
                                                        deviceName: nil,
                                                        isCurrentSession: true)

    static let mockWeb = UserSessionInfo(sessionId: "2",
                                         sessionName: "Firefox on Windows",
                                         deviceType: .web,
                                         isVerified: true,
                                         lastSeenIP: "2.0.0.2",
                                         lastSeenTimestamp: Date().timeIntervalSince1970 - 100,
                                         applicationName: "Element Web",
                                         applicationVersion: "1.0.0",
                                         applicationURL: nil,
                                         deviceModel: nil,
                                         deviceOS: "Windows 10",
                                         lastSeenIPLocation: nil,
                                         deviceName: "My Windows",
                                         isCurrentSession: false)

    static let mockAndroid = UserSessionInfo(sessionId: "3",
                                             sessionName: "Android",
                                             deviceType: .mobile,
                                             isVerified: false,
                                             lastSeenIP: "3.0.0.3",
                                             lastSeenTimestamp: Date().timeIntervalSince1970 - 10,
                                             applicationName: "Element Android",
                                             applicationVersion: "1.0.0",
                                             applicationURL: nil,
                                             deviceModel: nil,
                                             deviceOS: "Android 4.0",
                                             lastSeenIPLocation: nil,
                                             deviceName: "My Phone",
                                             isCurrentSession: false)

    static let mockDesktop = UserSessionInfo(sessionId: "1",
                                             sessionName: "macOS",
                                             deviceType: .desktop,
                                             isVerified: true,
                                             lastSeenIP: "1.0.0.1",
                                             lastSeenTimestamp: Date().timeIntervalSince1970 - 130_000,
                                             applicationName: "Element MacOS",
                                             applicationVersion: "1.0.0",
                                             applicationURL: nil,
                                             deviceModel: nil,
                                             deviceOS: "macOS 12.5.1",
                                             lastSeenIPLocation: nil,
                                             deviceName: "My Mac",
                                             isCurrentSession: false)
}
