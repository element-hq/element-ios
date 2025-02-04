// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension Array where Element: Equatable {

/// Remove first collection element that is equal to the given `object`
/// Credits: https://stackoverflow.com/a/45008042
    mutating func vc_removeFirstOccurrence(of object: Element) {
        guard let index = firstIndex(of: object) else {
            return
        }
        remove(at: index)
    }    
}
