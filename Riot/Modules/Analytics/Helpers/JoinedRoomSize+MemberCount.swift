// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import AnalyticsEvents

extension AnalyticsEvent.JoinedRoom.RoomSize {
    init?(memberCount: UInt) {
        switch memberCount {
        case 2:
            self = .Two
        case 3...10:
            self = .ThreeToTen
        case 11...100:
            self = .ElevenToOneHundred
        case 101...1000:
            self = .OneHundredAndOneToAThousand
        case 1001...:
            self = .MoreThanAThousand
        default:
            return nil
        }
    }
}
