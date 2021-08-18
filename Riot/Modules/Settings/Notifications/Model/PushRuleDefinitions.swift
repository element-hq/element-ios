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

enum NotificationIndex {
    case off
    case silent
    case noisy
}

enum PushRuleId: String {
    
    // Default Override Rules
    case disableAll = ".m.rule.master"
    case suppressBots = ".m.rule.suppress_notices"
    case inviteMe = ".m.rule.invite_for_me"
    case peopleJoinLeave = ".m.rule.member_event"
    case containDisplayName = ".m.rule.contains_display_name"
    case tombstone = ".m.rule.tombstone"
    case roomNotif = ".m.rule.roomnotif"
    // Default Content Rules
    case containUserName = ".m.rule.contains_user_name"
    case keywords = "_keywords"
    // Default Underride Rules
    case call = ".m.rule.call"
    case oneToOneEncryptedRoom = ".m.rule.encrypted_room_one_to_one"
    case oneToOneRoom = ".m.rule.room_one_to_one"
    case allOtherMessages = ".m.rule.message"
    case encrypted = ".m.rule.encrypted"
    // Not documented
    case fallback = ".m.rule.fallback"
    case reaction = ".m.rule.reaction"
}

func standardActions(for ruleId: PushRuleId, index: NotificationIndex) -> NotificationStandardActions? {
    switch ruleId {
    case .containDisplayName:
        switch index {
        case .off: return .disabled
        case .silent: return .notify
        case .noisy: return .highlightDefaultSound
        }
    case .containUserName:
        switch index {
        case .off: return .disabled
        case .silent: return .notify
        case .noisy: return .highlightDefaultSound
        }
    case .roomNotif:
        switch index {
        case .off: return .disabled
        case .silent: return .notify
        case .noisy: return .highlight
        }
    case .oneToOneRoom:
        switch index {
        case .off: return .dontNotify
        case .silent: return .notify
        case .noisy: return .notifyDefaultSound
        }
    case .oneToOneEncryptedRoom:
        switch index {
        case .off: return .dontNotify
        case .silent: return .notify
        case .noisy: return .notifyDefaultSound
        }
    case .allOtherMessages:
        switch index {
        case .off: return .dontNotify
        case .silent: return .notify
        case .noisy: return .notifyDefaultSound
        }
    case .encrypted:
        switch index {
        case .off: return .dontNotify
        case .silent: return .notify
        case .noisy: return .notifyDefaultSound
        }
    case .inviteMe:
        switch index {
        case .off: return .disabled
        case .silent: return .notify
        case .noisy: return .notifyDefaultSound
        }
    case .call:
        switch index {
        case .off: return .disabled
        case .silent: return .notify
        case .noisy: return .notifyRingSound
        }
    case .suppressBots:
        switch index {
        case .off: return .dontNotify
        case .silent: return .disabled
        case .noisy: return .notifyDefaultSound
        }
    case .tombstone:
        switch index {
        case .off: return .disabled
        case .silent: return .notify
        case .noisy: return .highlight
        }
    default: return nil
    }
}
