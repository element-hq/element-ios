//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A static definition of the different actions that can be defined on push rules.
///
/// It is defined similarly across Web and Android.
enum NotificationStandardActions {
    case notify
    case notifyDefaultSound
    case notifyRingSound
    case highlight
    case highlightDefaultSound
    case dontNotify
    case disabled
    
    var actions: NotificationActions? {
        switch self {
        case .notify:
            return NotificationActions(notify: true)
        case .notifyDefaultSound:
            return NotificationActions(notify: true, sound: "default")
        case .notifyRingSound:
            return NotificationActions(notify: true, sound: "ring")
        case .highlight:
            return NotificationActions(notify: true, highlight: true)
        case .highlightDefaultSound:
            return NotificationActions(notify: true, highlight: true, sound: "default")
        case .dontNotify:
            return NotificationActions(notify: false)
        case .disabled:
            return nil
        }
    }
}
