// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension MXSession {
    
    func avatarInput(for userId: String) -> AvatarInput {
        let user = self.user(withUserId: userId)
        
        return AvatarInput(mxContentUri: user?.avatarUrl,
                           matrixItemId: userId,
                           displayName: user?.displayname)
    }
    
    /// Clean the storage of a session by removing the expired contents.
    @objc func removeExpiredMessages() {
        var hasStoreChanged = false
        for room in self.rooms {
            hasStoreChanged = hasStoreChanged || room.summary.removeExpiredRoomContentsFromStore()
        }

        if hasStoreChanged {
            self.store.commit?()
        }
    }
}
