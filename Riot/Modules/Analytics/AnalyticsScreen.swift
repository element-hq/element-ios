// 
// Copyright 2021 New Vector Ltd
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

@objc enum AnalyticsScreen: Int {
    case welcome
    case login
    case register
    case forgotPassword
    case sidebar
    case home
    case favourites
    case people
    case rooms
    case searchRooms
    case searchMessages
    case searchPeople
    case searchFiles
    case room
    case roomPreview
    case roomDetails
    case roomMembers
    case user
    case roomSearch
    case roomUploads
    case roomSettings
    case roomNotifications
    case roomDirectory
    case switchDirectory
    case startChat
    case createRoom
    case settings
    case settingsSecurity
    case settingsDefaultNotifications
    case settingsMentionsAndKeywords
    case settingsNotifications
    case deactivateAccount
    case group
    case myGroups
    case inviteFriends
    case threadList
    case spaceMenu
    case spaceMembers
    case spaceExploreRooms
    case dialpad
    case spaceBottomSheet
    case invites
    case createSpace

    /// The screen name reported to the AnalyticsEvent.
    var screenName: AnalyticsEvent.MobileScreen.ScreenName {
        switch self {
        case .welcome:
            return .Welcome
        case .login:
            return .Login
        case .register:
            return .Register
        case .forgotPassword:
            return .ForgotPassword
        case .sidebar:
            return .Sidebar
        case .home:
            return .Home
        case .favourites:
            return .Favourites
        case .people:
            return .People
        case .rooms:
            return .Rooms
        case .searchRooms:
            return .SearchRooms
        case .searchMessages:
            return .SearchMessages
        case .searchPeople:
            return .SearchPeople
        case .searchFiles:
            return .SearchFiles
        case .room:
            return .Room
        case .roomDetails:
            return .RoomDetails
        case .roomMembers:
            return .RoomMembers
        case .user:
            return .User
        case .roomPreview:
            return .RoomPreview
        case .roomSearch:
            return .RoomSearch
        case .roomUploads:
            return .RoomUploads
        case .roomSettings:
            return .RoomSettings
        case .roomNotifications:
            return .RoomNotifications
        case .roomDirectory:
            return .RoomDirectory
        case .switchDirectory:
            return .SwitchDirectory
        case .startChat:
            return .StartChat
        case .createRoom:
            return .CreateRoom
        case .settings:
            return .Settings
        case .settingsSecurity:
            return .SettingsSecurity
        case .settingsDefaultNotifications:
            return .SettingsDefaultNotifications
        case .settingsMentionsAndKeywords:
            return .SettingsMentionsAndKeywords
        case .settingsNotifications:
            return .SettingsNotifications
        case .deactivateAccount:
            return .DeactivateAccount
        case .group:
            return .Group
        case .myGroups:
            return .MyGroups
        case .inviteFriends:
            return .InviteFriends
        case .threadList:
            return .ThreadList
        case .spaceMenu:
            return .SpaceMenu
        case .spaceMembers:
            return .SpaceMembers
        case .spaceExploreRooms:
            return .SpaceExploreRooms
        case .dialpad:
            return .Dialpad
        case .spaceBottomSheet:
            return .SpaceBottomSheet
        case .invites:
            return .Invites
        case .createSpace:
            return .CreateSpace
        }
    }
}
