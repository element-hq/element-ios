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
import UIKit

// MARK: - Coordinator

enum AllChatsLayoutEditorCoordinatorResult {
    case cancel
    case done(_ newSettings: AllChatsLayoutSettings)
}

// MARK: View model

enum AllChatsLayoutEditorViewModelResult {
    case cancel
    case done(_ newSettings: AllChatsLayoutSettings)
    case addPinnedSpace
}

// MARK: View

struct AllChatsLayoutEditorSection: Identifiable, Equatable {
    let id = UUID().uuidString
    let type: AllChatsLayoutSectionType
    let name: String
    let image: UIImage
    var selected: Bool
}

struct AllChatsLayoutEditorFilter: Identifiable, Equatable {
    let id = UUID().uuidString
    let type: AllChatsLayoutFilterType
    let name: String
    let image: UIImage
    var selected: Bool
}

struct AllChatsLayoutEditorSortingOption: Identifiable, Equatable {
    let id = UUID().uuidString
    let type: AllChatsLayoutSortingType
    let name: String
    var selected: Bool
}

struct AllChatsLayoutEditorViewState: BindableState {
    var sections: [AllChatsLayoutEditorSection]
    var filters: [AllChatsLayoutEditorFilter]
    var sortingOptions: [AllChatsLayoutEditorSortingOption]
    var pinnedSpaces: [SpaceSelectorListItemData]
}

enum AllChatsLayoutEditorViewAction {
    case tappedSectionItem(_ section: AllChatsLayoutEditorSection)
    case tappedFilterItem(_ filter: AllChatsLayoutEditorFilter)
    case tappedSortingOption(_ filter: AllChatsLayoutEditorSortingOption)
    case addPinnedSpace
    case removePinnedSpace(_ item: SpaceSelectorListItemData)
    case cancel
    case done
}
