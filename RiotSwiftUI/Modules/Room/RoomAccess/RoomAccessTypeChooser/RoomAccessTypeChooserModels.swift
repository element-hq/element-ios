// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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

/// Actions to be performed on the `ViewModel` State
enum RoomAccessTypeChooserStateAction {
    case updateAccessItems([RoomAccessTypeChooserAccessItem])
    case updateShowUpgradeRoomAlert(Bool)
    case updateWaitingMessage(String?)
}

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
