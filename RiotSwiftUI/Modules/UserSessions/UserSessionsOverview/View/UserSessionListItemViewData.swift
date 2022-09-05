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

/// View data for UserSessionListItem
struct UserSessionListItemViewData: Identifiable {
    
    // MARK: - Properties
    
    var id: String {
        return sessionId
    }
    
    let sessionId: String

    let sessionName: String?
    
    let deviceType: DeviceType
    
    let isVerified: Bool
    
    let lastActivityDate: TimeInterval?
    
    let deviceAvatarViewData: DeviceAvatarViewData
    
    // MARK: - Setup
    
    init(sessionId: String,
         sessionName: String?,
         deviceType: DeviceType,
         isVerified: Bool,
         lastActivityDate: TimeInterval?) {
        self.sessionId = sessionId
        self.sessionName = sessionName
        self.deviceType = deviceType
        self.isVerified = isVerified
        self.lastActivityDate = lastActivityDate
        self.deviceAvatarViewData = DeviceAvatarViewData(deviceType: deviceType, isVerified: isVerified)
    }
}

extension UserSessionListItemViewData {
        
    init(userSessionInfo: UserSessionInfo) {
        self.init(sessionId: userSessionInfo.sessionId, sessionName: userSessionInfo.sessionName, deviceType: userSessionInfo.deviceType, isVerified: userSessionInfo.isVerified, lastActivityDate: userSessionInfo.lastSeenTimestamp)
    }
}
