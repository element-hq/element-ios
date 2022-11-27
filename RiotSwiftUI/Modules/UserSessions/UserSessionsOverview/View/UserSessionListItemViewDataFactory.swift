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
    func create(from sessionInfo: UserSessionInfo,
                isSelected: Bool = false) -> UserSessionListItemViewData {
        let sessionName = UserSessionNameFormatter.sessionName(deviceType: sessionInfo.deviceType,
                                                               sessionDisplayName: sessionInfo.name)
        let sessionDetails = buildSessionDetails(sessionInfo: sessionInfo)
        let deviceAvatarViewData = DeviceAvatarViewData(deviceType: sessionInfo.deviceType,
                                                        verificationState: sessionInfo.verificationState)
        return UserSessionListItemViewData(sessionId: sessionInfo.id,
                                           sessionName: sessionName,
                                           sessionDetails: sessionDetails,
                                           deviceAvatarViewData: deviceAvatarViewData,
                                           sessionDetailsIcon: getSessionDetailsIcon(isActive: sessionInfo.isActive),
                                           isSelected: isSelected,
                                           lastSeenIP: sessionInfo.lastSeenIP,
                                           lastSeenIPLocation: sessionInfo.lastSeenIPLocation)
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
        // Start by creating the main part of the details string.
        
        var lastActivityDateString: String?
        if let lastActivityDate = sessionInfo.lastSeenTimestamp {
            lastActivityDateString = UserSessionLastActivityFormatter.lastActivityDateString(from: lastActivityDate)
        }
        var sessionDetailsString = ""
        if let lastActivityDateString = lastActivityDateString, lastActivityDateString.isEmpty == false {
            sessionDetailsString = VectorL10n.userSessionItemDetailsLastActivity(lastActivityDateString)
        }
        
        // Prepend the verification state if one is known.
        let sessionStatusText: String?
        switch sessionInfo.verificationState {
        case .verified:
            sessionStatusText = VectorL10n.userSessionVerifiedShort
        case .unverified, .permanentlyUnverified:
            sessionStatusText = VectorL10n.userSessionUnverifiedShort
        case .unknown:
            sessionStatusText = nil
        }
        
        if let sessionStatusText = sessionStatusText {
            if sessionDetailsString.isEmpty {
                sessionDetailsString = sessionStatusText
            } else {
                sessionDetailsString = VectorL10n.userSessionItemDetails(sessionStatusText, sessionDetailsString)
            }
        } else if sessionDetailsString.isEmpty {
            sessionDetailsString = VectorL10n.userSessionVerificationUnknownShort
        }
            
        return sessionDetailsString
    }
    
    private func getSessionDetailsIcon(isActive: Bool) -> String? {
        isActive ? nil : Asset.Images.userSessionListItemInactiveSession.name
    }
}
