//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// The actions defined on a push rule, used in the static push rule definitions.
struct NotificationActions: Equatable {
    let notify: Bool
    let highlight: Bool
    let sound: String?
    
    init(notify: Bool, highlight: Bool = false, sound: String? = nil) {
        self.notify = notify
        self.highlight = highlight
        self.sound = sound
    }
}
