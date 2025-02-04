//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
        case .oneToOneRoom, .oneToOnePollStart, .msc3930oneToOnePollStart, .oneToOnePollEnd, .msc3930oneToOnePollEnd:
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
        case .allOtherMessages, .pollStart, .msc3930pollStart, .pollEnd, .msc3930pollEnd:
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
