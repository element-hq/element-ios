// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Location authorization status
enum LocationAuthorizationStatus {
    
    /// Location status unknown
    case unknown
    
    /// Location access is denied
    case denied
    
    /// Location only authorized in foreground
    case authorizedInForeground
    
    /// Location only authorized in foreground and background
    case authorizedAlways
}
