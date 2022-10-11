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
    func create(from sessionInfo: UserSessionInfo, highlightSessionDetails: Bool = false) -> UserSessionListItemViewData {
        let sessionName = UserSessionNameFormatter.sessionName(deviceType: sessionInfo.deviceType,
                                                               sessionDisplayName: sessionInfo.name)
        let sessionDetails = buildSessionDetails(sessionInfo: sessionInfo)
        let deviceAvatarViewData = DeviceAvatarViewData(deviceType: sessionInfo.deviceType,
                                                        verificationState: sessionInfo.verificationState)
        return UserSessionListItemViewData(sessionId: sessionInfo.id,
                                           sessionName: sessionName,
                                           sessionDetails: sessionDetails,
                                           highlightSessionDetails: highlightSessionDetails,
                                           deviceAvatarViewData: deviceAvatarViewData,
                                           sessionDetailsIcon: getSessionDetailsIcon(isActive: sessionInfo.isActive))
    }
    
    private func buildSessionDetails(sessionInfo: UserSessionInfo) -> String {
        if sessionInfo.isActive {
            return activeSessionDetails(sessionInfo: sessionInfo)
        } else {
            return inactiveSessionDetails(sessionInfo: sessionInfo)
        }
    }
    
    private func inactiveSessionDetails(sessionInfo: UserSessionInfo) -> String {
        if let lastActivityDate = sessionInfo.lastSeenTimestamp {
            let lastActivityDateString = InactiveUserSessionLastActivityFormatter.lastActivityDateString(from: lastActivityDate)
            return VectorL10n.userInactiveSessionItemWithDate(lastActivityDateString)
        }
        return VectorL10n.userInactiveSessionItem
    }
    
    private func activeSessionDetails(sessionInfo: UserSessionInfo) -> String {
        let sessionDetailsString: String
        
        let sessionStatusText: String
        switch sessionInfo.verificationState {
        case .verified:
            sessionStatusText = VectorL10n.userSessionVerifiedShort
        case .unverified:
            sessionStatusText = VectorL10n.userSessionUnverifiedShort
        case .unknown:
            sessionStatusText = VectorL10n.userSessionVerificationUnknownShort
        }
        
        var lastActivityDateString: String?
        
        if let lastActivityDate = sessionInfo.lastSeenTimestamp {
            lastActivityDateString = UserSessionLastActivityFormatter.lastActivityDateString(from: lastActivityDate)
        }
        
        if sessionInfo.isCurrent {
            sessionDetailsString = VectorL10n.userOtherSessionUnverifiedCurrentSessionDetails(sessionStatusText)
        } else if let lastActivityDateString = lastActivityDateString, lastActivityDateString.isEmpty == false {
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
