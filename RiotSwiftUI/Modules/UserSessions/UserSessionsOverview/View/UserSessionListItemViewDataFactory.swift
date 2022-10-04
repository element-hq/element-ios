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

struct UserSessionListItemViewDataFactory {
    
    func create(from session: UserSessionInfo) -> UserSessionListItemViewData {
        let sessionName = UserSessionNameFormatter.sessionName(deviceType: session.deviceType,
                                                               sessionDisplayName: session.name)
        let sessionDetails = buildSessionDetails(isVerified: session.isVerified,
                                                 lastActivityDate: session.lastSeenTimestamp,
                                                 isActive: session.isActive)
        let deviceAvatarViewData = DeviceAvatarViewData(deviceType: session.deviceType,
                                                        isVerified: session.isVerified)
        return UserSessionListItemViewData(sessionId: session.id,
                                           sessionName: sessionName,
                                           sessionDetails: sessionDetails,
                                           deviceAvatarViewData: deviceAvatarViewData,
                                           sessionDetailsIcon: getSessionDetailsIcon(isActive: session.isActive))
    }
    
    private func buildSessionDetails(isVerified: Bool, lastActivityDate: TimeInterval?, isActive: Bool) -> String {
        if isActive {
            return activeSessionDetails(isVerified: isVerified, lastActivityDate: lastActivityDate)
        } else {
            return inactiveSessionDetails(lastActivityDate: lastActivityDate)
        }
    }
    
    private func inactiveSessionDetails(lastActivityDate: TimeInterval?) -> String {
        if let lastActivityDate = lastActivityDate {
            let lastActivityDateString = InactiveUserSessionLastActivityFormatter.lastActivityDateString(from: lastActivityDate)
            return VectorL10n.userInactiveSessionItemWithDate(lastActivityDateString)
        }
        return VectorL10n.userInactiveSessionItem
    }
    
    private func activeSessionDetails(isVerified: Bool, lastActivityDate: TimeInterval?) -> String {
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
    
    private func getSessionDetailsIcon(isActive: Bool) -> String? {
        isActive ? nil : Asset.Images.userSessionListItemInactiveSession.name
    }
}
