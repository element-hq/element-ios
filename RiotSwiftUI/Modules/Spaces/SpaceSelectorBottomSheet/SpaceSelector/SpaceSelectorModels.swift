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
    case cancel
    case homeSelected
    case spaceSelected(_ item: SpaceSelectorListItemData)
    case spaceDisclosure(_ item: SpaceSelectorListItemData)
    case createSpace(_ parentSpaceId: String?)
}

// MARK: View model

let SpaceSelectorListItemDataHomeSpaceId = "SpaceSelectorListItemDataHomeSpaceId"

struct SpaceSelectorListItemData {
    let id: String
    let avatar: AvatarInput?
    let icon: UIImage?
    let displayName: String?
    let notificationCount: UInt
    let highlightedNotificationCount: UInt
    let hasSubItems: Bool
    
    init(id: String,
         avatar: AvatarInput? = nil,
         icon: UIImage? = nil,
         displayName: String?,
         notificationCount: UInt = 0,
         highlightedNotificationCount: UInt = 0,
         hasSubItems: Bool = false) {
        self.id = id
        self.avatar = avatar
        self.icon = icon
        self.displayName = displayName
        self.notificationCount = notificationCount
        self.highlightedNotificationCount = highlightedNotificationCount
        self.hasSubItems = hasSubItems
    }
}

extension SpaceSelectorListItemData: Identifiable, Equatable {}

enum SpaceSelectorViewModelResult {
    case cancel
    case homeSelected
    case spaceSelected(_ item: SpaceSelectorListItemData)
    case spaceDisclosure(_ item: SpaceSelectorListItemData)
    case createSpace
}

// MARK: View

struct SpaceSelectorViewState: BindableState {
    var items: [SpaceSelectorListItemData]
    var selectedSpaceId: String?
    var parentName: String?
}

enum SpaceSelectorViewAction {
    case cancel
    case spaceSelected(_ item: SpaceSelectorListItemData)
    case spaceDisclosure(_ item: SpaceSelectorListItemData)
    case createSpace
}
