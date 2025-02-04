// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct RoomAvatarViewData: AvatarViewDataProtocol {
    let roomId: String
    let displayName: String?
    let avatarUrl: String?
    let mediaManager: MXMediaManager?
    
    var matrixItemId: String {
        return roomId
    }
    
    var fallbackImages: [AvatarFallbackImage]? {
        [.matrixItem(matrixItemId, displayName)]
    }
}
