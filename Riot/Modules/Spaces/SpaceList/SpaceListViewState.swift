// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceList SpaceList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SpaceListViewController view state
enum SpaceListViewState {
    case loading
    case loaded(_ sections: [SpaceListSection])
    case selectionChanged(_ indexPath: IndexPath)
    case error(Error)
}
