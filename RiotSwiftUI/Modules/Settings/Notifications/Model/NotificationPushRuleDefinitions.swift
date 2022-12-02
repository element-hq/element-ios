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

extension NotificationPushRuleId {
    /// A static definition of the push rule actions.
    ///
    /// It is defined similarly across Web and Android.
    /// - Parameter index: The notification index for which to get the actions for.
    /// - Returns: The associated `NotificationStandardActions`.
    func standardActions(for index: NotificationIndex) -> NotificationStandardActions {
        switch self {
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
        case .oneToOneRoom, .msc3930oneToOnePollStart, .msc3930oneToOnePollEnd:
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
        case .allOtherMessages, .msc3930pollStart, .msc3930pollEnd:
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
        case .keywords:
            switch index {
            case .off: return .disabled
            case .silent: return .notify
            case .noisy: return .highlightDefaultSound
            }
        }
    }
}
