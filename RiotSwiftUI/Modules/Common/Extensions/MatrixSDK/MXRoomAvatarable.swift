//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
extension MXRoom: Avatarable {
    var mxContentUri: String? {
        summary.avatar
    }
    
    var matrixItemId: String {
        roomId
    }
    
    var displayName: String? {
        summary.displayName
    }
}
