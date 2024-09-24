// File created from ScreenTemplate
// $ createScreen.sh CreateRoom/EnterNewRoomDetails EnterNewRoomDetails
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// EnterNewRoomDetailsViewController view state
enum EnterNewRoomDetailsViewState {
    case loading
    case loaded
    case error(Error)
}
