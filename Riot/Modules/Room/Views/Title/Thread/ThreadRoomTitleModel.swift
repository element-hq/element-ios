// 
// Copyright 2024 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct ThreadRoomTitleModel {
    let roomAvatar: AvatarViewDataProtocol?
    let roomEncryptionBadge: UIImage?
    let roomDisplayName: String?
    
    static let empty = ThreadRoomTitleModel(roomAvatar: nil,
                                            roomEncryptionBadge: nil,
                                            roomDisplayName: nil)
}
