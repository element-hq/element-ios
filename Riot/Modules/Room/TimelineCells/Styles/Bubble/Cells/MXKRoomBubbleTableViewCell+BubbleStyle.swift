// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension MXKRoomBubbleTableViewCell {
    
    // Enables to get existing bubble background view
    // This used while there is no dedicated cell classes for bubble style
    var messageBubbleBackgroundView: RoomMessageBubbleBackgroundView? {
        
        let foundView = self.contentView.subviews.first { view in
            return view is RoomMessageBubbleBackgroundView
        }
        return foundView as? RoomMessageBubbleBackgroundView
    }
}
