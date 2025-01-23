// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixSDK

@objcMembers
public class MockRoomListData: MXRoomListData {
    
    public init(withRooms rooms: [MXRoomSummaryProtocol]) {
        super.init(rooms: rooms,
                   counts: MXStoreRoomListDataCounts(withRooms: rooms,
                                                     total: nil),
                   paginationOptions: .none)
    }
    
}
