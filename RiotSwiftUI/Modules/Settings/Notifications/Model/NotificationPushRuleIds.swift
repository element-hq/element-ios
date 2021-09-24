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

/// The push rule ids used in notification settings and the static rule definitions.
enum NotificationPushRuleId: String {
    case suppressBots = ".m.rule.suppress_notices"
    case inviteMe = ".m.rule.invite_for_me"
    case containDisplayName = ".m.rule.contains_display_name"
    case tombstone = ".m.rule.tombstone"
    case roomNotif = ".m.rule.roomnotif"
    case containUserName = ".m.rule.contains_user_name"
    case call = ".m.rule.call"
    case oneToOneEncryptedRoom = ".m.rule.encrypted_room_one_to_one"
    case oneToOneRoom = ".m.rule.room_one_to_one"
    case allOtherMessages = ".m.rule.message"
    case encrypted = ".m.rule.encrypted"
    case keywords = "_keywords"
}


extension NotificationPushRuleId: Identifiable {
    var id: String {
        rawValue
    }
}

extension NotificationPushRuleId {
    var title: String {
        switch self {
        case .suppressBots:
            return VectorL10n.settingsMessagesByABot
        case .inviteMe:
            return VectorL10n.settingsRoomInvitations
        case .containDisplayName:
            return VectorL10n.settingsMessagesContainingDisplayName
        case .tombstone:
            return VectorL10n.settingsRoomUpgrades
        case .roomNotif:
            return VectorL10n.settingsMessagesContainingAtRoom
        case .containUserName:
            return VectorL10n.settingsMessagesContainingUserName
        case .call:
            return VectorL10n.settingsCallInvitations
        case .oneToOneEncryptedRoom:
            return VectorL10n.settingsEncryptedDirectMessages
        case .oneToOneRoom:
            return VectorL10n.settingsDirectMessages
        case .allOtherMessages:
            return VectorL10n.settingsGroupMessages
        case .encrypted:
            return VectorL10n.settingsEncryptedGroupMessages
        case .keywords:
            return VectorL10n.settingsMessagesContainingKeywords
        }
    }
}
