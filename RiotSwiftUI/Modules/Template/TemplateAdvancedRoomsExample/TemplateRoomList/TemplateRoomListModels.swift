//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Coordinator

struct TemplateRoomListRoom: Identifiable, Equatable {
    let id: String
    let avatar: AvatarInput
    let displayName: String?
}

/// Actions returned by the coordinator callback
enum TemplateRoomListCoordinatorAction {
    case didSelectRoom(String)
    case done
}

// MARK: - View model

/// Actions sent by the`ViewModel` to the `Coordinator`.
enum TemplateRoomListViewModelAction {
    case didSelectRoom(String)
    case done
}

// MARK: - View

/// State managed by the `ViewModel` delivered to the `View`.
struct TemplateRoomListViewState: BindableState {
    var rooms: [TemplateRoomListRoom]
}

/// Actions send from the `View` to the `ViewModel`.
enum TemplateRoomListViewAction {
    case done
    case didSelectRoom(String)
}
