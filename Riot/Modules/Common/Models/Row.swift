// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 Vector Creations Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objcMembers
final class Row: NSObject {
    
    let tag: Int
    
    init(withTag tag: Int) {
        self.tag = tag
        super.init()
    }
    
    static func row(withTag tag: Int) -> Row {
        return Row(withTag: tag)
    }
    
}
