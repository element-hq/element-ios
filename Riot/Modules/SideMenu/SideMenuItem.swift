// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// SideMenuItem represents side menu actions
enum SideMenuItem {
    case inviteFriends
    case settings
    case help
    case feedback
}

extension SideMenuItem {
    
    var title: String {
        let title: String

        switch self {
        case .inviteFriends:
            title = VectorL10n.sideMenuActionInviteFriends
        case .settings:
            title = VectorL10n.sideMenuActionSettings
        case .help:
            title = VectorL10n.sideMenuActionHelp
        case .feedback:
            title = VectorL10n.sideMenuActionFeedback
        }

        return title
    }
    
    var icon: UIImage {
        let icon: UIImage

        switch self {
        case .inviteFriends:
            icon = Asset.Images.sideMenuActionIconShare.image
        case .settings:
            icon = Asset.Images.sideMenuActionIconSettings.image
        case .help:
            icon = Asset.Images.sideMenuActionIconHelp.image
        case .feedback:
            icon = Asset.Images.sideMenuActionIconFeedback.image
        }

        return icon
    }
}
