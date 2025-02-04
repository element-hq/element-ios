// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// DeepLinkOption represents deep link paths with their respective parameters
enum DeepLinkOption {
    
    /// Used for SSO callback only when VoiceOver is enabled
    case connect(_ loginToken: String, _ transactionId: String)
}
