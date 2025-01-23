// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 Vector Creations Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension MXSessionState: Comparable {
    
    public static func < (lhs: MXSessionState, rhs: MXSessionState) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
}
