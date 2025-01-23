// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import AnalyticsEvents

@objc enum AnalyticsViewRoomActiveSpace: Int {
    case unknown
    case home
    case meta
    case `private`
    case `public`

    var space: AnalyticsEvent.ViewRoom.ActiveSpace? {
        switch self {
        case .unknown:
            return nil
        case .home:
            return .Home
        case .meta:
            return .Meta
        case .private:
            return .Private
        case .public:
            return .Public
        }
    }
}
