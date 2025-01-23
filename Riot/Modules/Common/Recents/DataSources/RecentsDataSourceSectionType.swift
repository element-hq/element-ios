// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objc enum RecentsDataSourceSectionType: Int {
    case crossSigningBanner
    case secureBackupBanner
    case directory
    case invites
    case favorites
    case people
    case conversation
    case lowPriority
    case serverNotice
    case suggestedRooms
    case breadcrumbs
    case searchedRoom
    case allChats
    case unknown
}
