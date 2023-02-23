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

@objc enum AnalyticsViewRoomTrigger: Int {
    case unknown
    case created
    case messageSearch
    case messageUser
    case notification
    case predecessor
    case roomDirectory
    case roomList
    case spaceHierarchy
    case timeline
    case tombstone
    case verificationRequest
    case widget
    case roomMemberDetail
    case fileSearch
    case roomSearch
    case searchContactDetail
    case spaceMemberDetail
    case inCall
    case spaceMenu
    case spaceSettings
    case roomPreview
    case permalink
    case linkShare
    case exploreRooms
    case spaceMembers
    case spaceBottomSheet

    var trigger: AnalyticsEvent.ViewRoom.Trigger? {
        switch self {
        case .unknown:
            return nil
        case .created:
            return .Created
        case .messageSearch:
            return .MessageSearch
        case .messageUser:
            return .MessageUser
        case .notification:
            return .Notification
        case .predecessor:
            return .Predecessor
        case .roomDirectory:
            return .RoomDirectory
        case .roomList:
            return .RoomList
        case .spaceHierarchy:
            return .SpaceHierarchy
        case .timeline:
            return .Timeline
        case .tombstone:
            return .Tombstone
        case .verificationRequest:
            return .VerificationRequest
        case .widget:
            return .Widget
        case .fileSearch:
            return .MobileFileSearch
        case .roomSearch:
            return .MobileRoomSearch
        case .roomMemberDetail:
            return .MobileRoomMemberDetail
        case .searchContactDetail:
            return .MobileSearchContactDetail
        case .spaceMemberDetail:
            return .MobileSpaceMemberDetail
        case .inCall:
            return .MobileInCall
        case .spaceMenu:
            return .MobileSpaceMenu
        case .spaceSettings:
            return .MobileSpaceSettings
        case .roomPreview:
            return .MobileRoomPreview
        case .permalink:
            return .MobilePermalink
        case .linkShare:
            return .MobileLinkShare
        case .exploreRooms:
            return .MobileExploreRooms
        case .spaceMembers:
            return .MobileSpaceMembers
        case .spaceBottomSheet:
            return .MobileSpaceBottomSheet
        }
    }
}
