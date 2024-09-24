// File created from ScreenTemplate
// $ createScreen.sh Room2/RoomInfo RoomInfoList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// RoomInfoListViewController view state
enum RoomInfoListViewState {
    case loading
    case loaded(viewData: RoomInfoListViewData)
    case error(Error)
}
