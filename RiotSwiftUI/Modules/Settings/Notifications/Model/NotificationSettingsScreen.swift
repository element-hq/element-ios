//
// Copyright 2021 New Vector Ltd
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

/// The notification settings screen definitions, used when calling the coordinator.
@objc enum NotificationSettingsScreen: Int {
    case defaultNotifications
    case mentionsAndKeywords
    case other
}

extension NotificationSettingsScreen: CaseIterable { }

extension NotificationSettingsScreen: Identifiable {
    var id: Int { rawValue }
}

extension NotificationSettingsScreen {
    /// Defines which rules are handled by each of the screens.
    var pushRules: [NotificationPushRuleId] {
        switch self {
        case .defaultNotifications:
            return [.oneToOneRoom, .allOtherMessages, .oneToOneEncryptedRoom, .encrypted]
        case .mentionsAndKeywords:
            return [.containDisplayName, .containUserName, .roomNotif, .keywords]
        case .other:
            return [.inviteMe, .call, .suppressBots, .tombstone]
        }
    }
}
