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

/// View data for UserSessionCardView
struct UserSessionCardViewData {
    
    // MARK: - Constants
    
    private static let userSessionNameFormatter = UserSessionNameFormatter()
    private static let lastActivityDateFormatter = UserSessionLastActivityFormatter()
        
    // MARK: - Properties
    
    var id: String {
        return sessionId
    }
    
    let sessionId: String

    let sessionName: String
    
    let isVerified: Bool
    
    let lastActivityDateString: String?
    
    let lastSeenIPInfo: String?
    
    let deviceAvatarViewData: DeviceAvatarViewData
    
    /// Indicate if the current user session is shown and to adpat the layout
    let isCurrentSessionDisplayMode: Bool
    
    // MARK: - Setup
    
    init(sessionId: String,
         sessionDisplayName: String?,
         deviceType: DeviceType,
         isVerified: Bool,
         lastActivityTimestamp: TimeInterval?,
         lastSeenIP: String?,
         isCurrentSessionDisplayMode: Bool = false) {
        self.sessionId = sessionId
        self.sessionName = Self.userSessionNameFormatter.sessionName(deviceType: deviceType, sessionDisplayName: sessionDisplayName)
        self.isVerified = isVerified
        
        var lastActivityDateString: String?
        
        if let lastActivityTimestamp = lastActivityTimestamp {
            lastActivityDateString = Self.lastActivityDateFormatter.lastActivityDateString(from: lastActivityTimestamp)
        }
        
        self.lastActivityDateString = lastActivityDateString
        self.lastSeenIPInfo = lastSeenIP
        self.deviceAvatarViewData = DeviceAvatarViewData(deviceType: deviceType, isVerified: nil)
        
        self.isCurrentSessionDisplayMode = isCurrentSessionDisplayMode
    }
}

extension UserSessionCardViewData {
        
    init(userSessionInfo: UserSessionInfo, isCurrentSessionDisplayMode: Bool = false) {
        self.init(sessionId: userSessionInfo.sessionId, sessionDisplayName: userSessionInfo.sessionName, deviceType: userSessionInfo.deviceType, isVerified: userSessionInfo.isVerified, lastActivityTimestamp: userSessionInfo.lastSeenTimestamp, lastSeenIP: userSessionInfo.lastSeenIP, isCurrentSessionDisplayMode: isCurrentSessionDisplayMode)
    }
}
