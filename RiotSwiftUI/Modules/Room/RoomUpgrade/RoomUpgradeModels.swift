//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Coordinator

enum RoomUpgradeCoordinatorResult {
    case cancel(_ roomId: String)
    case done(_ roomId: String)
}

// MARK: View model

enum RoomUpgradeViewModelResult {
    case cancel(_ roomId: String)
    case done(_ roomId: String)
}

// MARK: View

struct RoomUpgradeViewState: BindableState {
    var waitingMessage: String?
    var isLoading: Bool
    var parentSpaceName: String?
}

enum RoomUpgradeViewAction {
    case cancel
    case done(_ autoInviteUsers: Bool)
}
