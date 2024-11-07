// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct UserAvatarViewData: AvatarViewDataProtocol {
    let userId: String
    let displayName: String?
    let avatarUrl: String?
    let mediaManager: MXMediaManager?
    
    var matrixItemId: String {
        return userId
    }
    
    var fallbackImages: [AvatarFallbackImage]? {
        [.matrixItem(matrixItemId, displayName), .image(Asset.Images.tabPeople.image, .scaleAspectFill)]
    }
}
