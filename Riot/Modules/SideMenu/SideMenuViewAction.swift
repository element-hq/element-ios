// File created from ScreenTemplate
// $ createScreen.sh SideMenu SideMenu
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SideMenuViewController view actions exposed to view model
enum SideMenuViewAction {
    case loadData
    case tap(menuItem: SideMenuItem, sourceView: UIView)
    case tapHeader(sourceView: UIView)
}
