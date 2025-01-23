//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Enables to build last activity date string
enum UserSessionLastActivityFormatter {
    private static var lastActivityDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()
    
    /// Session last activity string
    static func lastActivityDateString(from lastActivityTimestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: lastActivityTimestamp)
        
        return Self.lastActivityDateFormatter.string(from: date)
    }
}
