// File created from ScreenTemplate
// $ createScreen.sh Room2/RoomInfo RoomInfoList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

enum RoomInfoListTarget: Equatable {
    case settings(_ field: RoomSettingsViewControllerField = RoomSettingsViewControllerFieldNone)
    case members
    case uploads
    case integrations
    case search
    case notifications
    case pollHistory
    
    var tabIndex: UInt? {
        switch self {
        case .members:
            return 0
        case .uploads:
            return 1
        case .settings:
            return 2
        default:
            return nil
        }
    }
    
}

/// RoomInfoListViewController view actions exposed to view model
enum RoomInfoListViewAction {
    case loadData
    case navigate(target: RoomInfoListTarget)
    case leave
    case cancel
    case report
}
