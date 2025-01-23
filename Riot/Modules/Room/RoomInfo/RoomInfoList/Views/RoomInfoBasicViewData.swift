// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct RoomInfoBasicViewData {
    let avatarUrl: String?
    let mediaManager: MXMediaManager?
    
    let roomId: String
    let roomDisplayName: String?
    let mainRoomAlias: String?
    let roomTopic: String?
    let encryptionImage: UIImage?
    let isEncrypted: Bool
    let isDirect: Bool
    let directUserId: String?
    let directUserPresence: MXPresence
}
