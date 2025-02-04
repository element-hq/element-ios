// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension MXKKeyPreSharingStrategy {
    init?(key: String?) {
        guard let key = key else {
            return nil
        }

        switch key {
        case "on_typing":
            self = .whenTyping
        case "on_room_opening":
            self = .whenEnteringRoom
        default:
            self = .none
        }
    }
}
