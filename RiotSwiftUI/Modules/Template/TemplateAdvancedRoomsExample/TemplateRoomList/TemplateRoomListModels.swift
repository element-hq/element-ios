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
