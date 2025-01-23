//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// View data for LiveLocationListItem
struct LiveLocationListItemViewData: Identifiable {
    var id: String {
        userId
    }
        
    let userId: String
    
    let isCurrentUser: Bool
    
    let avatarData: AvatarInputProtocol
    
    let displayName: String
        
    /// The location sharing expiration date
    let expirationDate: TimeInterval
    
    /// Last coordinatore update
    let lastUpdate: TimeInterval
}
