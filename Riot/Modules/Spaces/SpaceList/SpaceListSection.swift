// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// Space list sections
enum SpaceListSection {
    case home(_ viewData: SpaceListItemViewData)
    case spaces(_ viewDataList: [SpaceListItemViewData])
    case addSpace(_ viewData: SpaceListItemViewData)
}
