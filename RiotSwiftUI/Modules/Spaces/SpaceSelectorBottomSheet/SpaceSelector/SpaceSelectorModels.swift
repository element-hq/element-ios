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

// MARK: - Coordinator

enum SpaceSelectorCoordinatorResult {
    /// Cancel button has been presed
    case cancel
    /// Home Space (aka "All Chats") has been selected -> the app should switch to the home space
    case homeSelected
    /// A space has been selected -> the app should switch to this space
    case spaceSelected(_ item: SpaceSelectorListItemData)
    /// The disclosure button of a space has been pressed -> the parent coordinator should navigate to its sub-spaces
    case spaceDisclosure(_ item: SpaceSelectorListItemData)
    /// The create space button has been pressed
    case createSpace(_ parentSpaceId: String?)
}

// MARK: View model

enum SpaceSelectorConstants {
    /// Arbitrary ID for the home space (aka "All Chats")
    static let homeSpaceId = "SpaceSelectorListItemDataHomeSpaceId"
}

/// This structure contains all the data to display the information about a space
struct SpaceSelectorListItemData {
    /// Id of the space (`SpaceSelectorConstants.homeSpaceId` for the home space)
    let id: String
    /// avatar data of the space: set this property to `nil` if you want to display a space with a hardcoded icon
    let avatar: AvatarInput?
    /// hardcoded icon: only used if the avatar is not set
    let icon: UIImage?
    /// Displayname of the space
    let displayName: String?
    /// total number of notifications for this space
    let notificationCount: UInt
    /// total number of highlights for this space
    let highlightedNotificationCount: UInt
    /// Indicates if the space has sub spaces (condition the display of the disclosure button)
    let hasSubItems: Bool
    /// Indicates if the space has has already been joined
    let isJoined: Bool
    
    init(id: String,
         avatar: AvatarInput? = nil,
         icon: UIImage? = nil,
         displayName: String?,
         notificationCount: UInt = 0,
         highlightedNotificationCount: UInt = 0,
         hasSubItems: Bool = false,
         isJoined: Bool = false) {
        self.id = id
        self.avatar = avatar
        self.icon = icon
        self.displayName = displayName
        self.notificationCount = notificationCount
        self.highlightedNotificationCount = highlightedNotificationCount
        self.hasSubItems = hasSubItems
        self.isJoined = isJoined
    }
}

extension SpaceSelectorListItemData: Identifiable, Equatable { }

enum SpaceSelectorViewModelResult {
    /// Cancel button has been presed
    case cancel
    /// Home Space (aka "All Chats") has been selected -> the app should switch to the home space
    case homeSelected
    /// A space has been selected -> the app should switch to this space
    case spaceSelected(_ item: SpaceSelectorListItemData)
    /// The disclosure button of a space has been pressed -> the parent coordinator should navigate to its sub-spaces
    case spaceDisclosure(_ item: SpaceSelectorListItemData)
    /// The create space button has been pressed
    case createSpace
}

// MARK: View

struct SpaceSelectorViewState: BindableState {
    /// List of items that represents the list of sub space of the current space
    var items: [SpaceSelectorListItemData]
    /// Id of the currently selected space if there is a current space in the app
    var selectedSpaceId: String?
    /// String to be displayed as title for the navigation bar
    var navigationTitle: String
    /// `true` if the view should display the cancel button in the navigation bar
    let showCancel: Bool
}

enum SpaceSelectorViewAction {
    /// Cancel button has been presed
    case cancel
    /// A space has been selected
    case spaceSelected(_ item: SpaceSelectorListItemData)
    /// The disclosure button of a space has been pressed
    case spaceDisclosure(_ item: SpaceSelectorListItemData)
    /// The create space button has been pressed
    case createSpace
}
