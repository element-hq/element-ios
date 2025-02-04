//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum UserOtherSessionsFilter: Identifiable, Equatable, CaseIterable {
    var id: Self { self }
    case all
    case verified
    case unverified
    case inactive
}

extension UserOtherSessionsFilter {
    var menuLocalizedName: String {
        switch self {
        case .all:
            return VectorL10n.userOtherSessionFilterMenuAll
        case .verified:
            return VectorL10n.userOtherSessionFilterMenuVerified
        case .unverified:
            return VectorL10n.userOtherSessionFilterMenuUnverified
        case .inactive:
            return VectorL10n.userOtherSessionFilterMenuInactive
        }
    }
}
