// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// SpaceMenuViewController view state
enum SpaceMenuViewState {
    case loading
    case loaded
    case deselect
    case leaveOptions(_ displayName: String, _ isAdmin: Bool)
    case error(Error)
}
