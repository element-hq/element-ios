// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension Date {
    
    func daysBetween(date: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: self, to: date)
        return components.day ?? 0
    }
}
