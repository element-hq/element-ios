// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Supported destinations used by AppNavigator to navigate in screen hierarchy
enum AppNavigatorDestination {
    
    /// Show home space
    case homeSpace
        
    /// Show a space with specific id
    case space(_ spaceId: String)
}
