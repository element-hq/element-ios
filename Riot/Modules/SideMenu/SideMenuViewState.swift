// File created from ScreenTemplate
// $ createScreen.sh SideMenu SideMenu
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

struct SideMenuViewData {
    let userAvatarViewData: UserAvatarViewData
    let sideMenuItems: [SideMenuItem]
    let appVersion: String?
}

/// SideMenuViewController view state
enum SideMenuViewState {
    case loading
    case loaded(_ viewData: SideMenuViewData)
    case error(Error)
}
