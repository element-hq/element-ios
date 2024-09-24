// File created from ScreenTemplate
// $ createScreen.sh CreateRoom/EnterNewRoomDetails EnterNewRoomDetails
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import UIKit

/// EnterNewRoomDetailsViewController view actions exposed to view model
enum EnterNewRoomDetailsViewAction {
    case loadData
    case chooseAvatar(sourceView: UIView)
    case removeAvatar
    case cancel
    case create
}
