// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceList SpaceList
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SpaceListViewController view actions exposed to view model
enum SpaceListViewAction {
    case loadData    
    case selectRow(at: IndexPath, from: UIView?)
    case moreAction(at: IndexPath, from: UIView)
}
