// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Possible action related to a `SpaceMenuListViewCell` view data
enum SpaceMenuListItemAction {
    case showAllRoomsInHomeSpace
    case exploreSpaceMembers
    case exploreSpaceRooms
    case addRoom
    case addSpace
    case settings
    case leaveSpace
    case leaveSpaceAndChooseRooms
    case invite
}

/// Style of the `SpaceMenuListViewCell`
enum SpaceMenuListItemStyle {
    case normal
    case toggle
    case destructive
}

/// `SpaceMenuListItemViewDataDelegate` allows the table view cell to update its view accordingly with it's related data change
protocol SpaceMenuListItemViewDataDelegate: AnyObject {
    func spaceMenuItemValueDidChange(_ item: SpaceMenuListItemViewData)
}

/// `SpaceMenuListViewCell` view data
class SpaceMenuListItemViewData {
    let action: SpaceMenuListItemAction
    let style: SpaceMenuListItemStyle
    let title: String?
    let icon: UIImage?
    let isBeta: Bool
    
    /// Any value related to the type of data (e.g. `Bool` for `boolean` style, `nil` for `normal` and `destructive` style)
    var value: Any? {
        didSet {
            delegate?.spaceMenuItemValueDidChange(self)
        }
    }
    weak var delegate: SpaceMenuListItemViewDataDelegate?
    
    init(action: SpaceMenuListItemAction, style: SpaceMenuListItemStyle, title: String?, icon: UIImage?, value: Any?, isBeta: Bool = false) {
        self.action = action
        self.style = style
        self.title = title
        self.icon = icon
        self.value = value
        self.isBeta = isBeta
    }
}
