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

enum SpaceSelectorBottomSheetCoordinatorResult {
    case cancel
    case allSelected
    case spaceSelected(_ item: SpaceSelectorListItemData)
}

// MARK: View model

let SpaceSelectorListItemDataAllId = "SpaceSelectorListItemDataAllId"

struct SpaceSelectorListItemData {
    let id: String
    let avatar: AvatarInput?
    let icon: UIImage?
    let displayName: String?
}

extension SpaceSelectorListItemData: Identifiable, Equatable {}

enum SpaceSelectorBottomSheetViewModelResult {
    case cancel
    case allSelected
    case spaceSelected(_ item: SpaceSelectorListItemData)
}

// MARK: View

struct SpaceSelectorBottomSheetViewState: BindableState {
    var items: [SpaceSelectorListItemData]
}

enum SpaceSelectorBottomSheetViewAction {
    case cancel
    case spaceSelected(_ item: SpaceSelectorListItemData)
}
