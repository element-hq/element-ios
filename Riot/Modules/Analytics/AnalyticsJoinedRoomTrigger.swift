// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import AnalyticsEvents

@objc enum AnalyticsJoinedRoomTrigger: Int {
    case unknown
    case invite
    case notification
    case roomDirectory
    case roomPreview
    case slashCommand
    case spaceHierarchy
    case timeline
    case permalink
    
    var trigger: AnalyticsEvent.JoinedRoom.Trigger? {
        switch self {
        case .unknown:
            return nil
        case .invite:
            return .Invite
        case .notification:
            return .Notification
        case .roomDirectory:
            return .RoomDirectory
        case .roomPreview:
            return .RoomPreview
        case .slashCommand:
            return .SlashCommand
        case .spaceHierarchy:
            return .SpaceHierarchy
        case .timeline:
            return .Timeline
        case .permalink:
            return .MobilePermalink
        }
    }
}
