// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension MXFileStore {

    func displayName(ofUserWithId userId: String) async -> String? {
        await withCheckedContinuation({ continuation in
            asyncUsers(withUserIds: [userId]) { users in
                continuation.resume(returning: users.first?.displayname)
            }
        })
    }

}
