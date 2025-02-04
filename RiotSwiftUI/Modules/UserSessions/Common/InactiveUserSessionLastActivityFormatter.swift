//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class InactiveUserSessionLastActivityFormatter {
    private static var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateStyle = .medium
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()
    
    static func lastActivityDateString(from lastActivityTimestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: lastActivityTimestamp)
        return InactiveUserSessionLastActivityFormatter.dateFormatter.string(from: date)
    }
}
