// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import AnalyticsEvents

extension UserSessionProperties.AllChatsActiveFilter {
    var analyticsName: AnalyticsEvent.UserProperties.AllChatsActiveFilter {
        switch self {
        case .all:
            return .All
        case .unreads:
            return .Unreads
        case .favourites:
            return .Favourites
        case .people:
            return .People
        }
    }
}
