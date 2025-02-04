//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Coordinator

enum RoomAccessTypeChooserAccessType {
    case `private`
    case restricted
    case `public`
}

struct RoomAccessTypeChooserAccessItem: Identifiable, Equatable {
    let id: RoomAccessTypeChooserAccessType
    var isSelected: Bool
    let title: String
    let detail: String
    var badgeText: String?
}

/// Actions returned by the coordinator callback
enum RoomAccessTypeChooserCoordinatorAction {
    case spaceSelection(String, RoomAccessTypeChooserAccessType)
    case roomUpgradeNeeded(String, String)
    case done(String)
    case cancel(String)
}

// MARK: - View model

/// Actions sent by the`ViewModel` to the `Coordinator`.
enum RoomAccessTypeChooserViewModelAction {
    case spaceSelection(String, RoomAccessTypeChooserAccessType)
    case roomUpgradeNeeded(String, String)
    case done(String)
    case cancel(String)
}

// MARK: - View

/// State managed by the `ViewModel` delivered to the `View`.
struct RoomAccessTypeChooserViewState: BindableState {
    var accessItems: [RoomAccessTypeChooserAccessItem]
    var bindings: RoomAccessTypeChooserViewModelBindings
}

struct RoomAccessTypeChooserViewModelBindings {
    var showUpgradeRoomAlert: Bool
    var waitingMessage: String?
    var isLoading: Bool
}

/// Actions send from the `View` to the `ViewModel`.
enum RoomAccessTypeChooserViewAction {
    case cancel
    case done
    case didSelectAccessType(RoomAccessTypeChooserAccessType)
}
