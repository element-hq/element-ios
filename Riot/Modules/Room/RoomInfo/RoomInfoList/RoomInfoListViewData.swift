// File created from ScreenTemplate
// $ createScreen.sh Room2/RoomInfo RoomInfoList
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// View data object to represent view
struct RoomInfoListViewData {
    let numberOfMembers: Int
    let isEncrypted: Bool
    let isDirect: Bool
    let basicInfoViewData: RoomInfoBasicViewData
}
