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
    var id: String {
        sessionId
    }
    
    let sessionId: String

    let sessionName: String
    
    let sessionDetails: String
    
    let deviceAvatarViewData: DeviceAvatarViewData
    
    init(sessionId: String,
         sessionDisplayName: String?,
         deviceType: DeviceType,
         isVerified: Bool,
         lastActivityDate: TimeInterval?) {
        self.sessionId = sessionId
        sessionName = UserSessionNameFormatter.sessionName(deviceType: deviceType, sessionDisplayName: sessionDisplayName)
        sessionDetails = Self.buildSessionDetails(isVerified: isVerified, lastActivityDate: lastActivityDate)
        deviceAvatarViewData = DeviceAvatarViewData(deviceType: deviceType, isVerified: isVerified)
    }
    
    // MARK: - Private
    
    private static func buildSessionDetails(isVerified: Bool, lastActivityDate: TimeInterval?) -> String {
        let sessionDetailsString: String
        
        let sessionStatusText = isVerified ? VectorL10n.userSessionVerifiedShort : VectorL10n.userSessionUnverifiedShort
        
        var lastActivityDateString: String?
        
        if let lastActivityDate = lastActivityDate {
            lastActivityDateString = UserSessionLastActivityFormatter.lastActivityDateString(from: lastActivityDate)
        }

        if let lastActivityDateString = lastActivityDateString, lastActivityDateString.isEmpty == false {
            sessionDetailsString = VectorL10n.userSessionItemDetails(sessionStatusText, lastActivityDateString)
        } else {
            sessionDetailsString = sessionStatusText
        }
        
        return sessionDetailsString
    }
}

extension UserSessionListItemViewData {
    init(session: UserSessionInfo) {
        self.init(sessionId: session.id,
                  sessionDisplayName: session.name,
                  deviceType: session.deviceType,
                  isVerified: session.isVerified,
                  lastActivityDate: session.lastSeenTimestamp)
    }
}
