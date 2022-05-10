// 
// Copyright 2022 New Vector Ltd
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
