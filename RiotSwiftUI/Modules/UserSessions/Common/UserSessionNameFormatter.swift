//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Enables to build user session name
enum UserSessionNameFormatter {
    /// Session name with client name and session display name
    static func sessionName(sessionId: String, sessionDisplayName: String?) -> String {
        sessionDisplayName?.vc_nilIfEmpty() ?? sessionId
    }
}
