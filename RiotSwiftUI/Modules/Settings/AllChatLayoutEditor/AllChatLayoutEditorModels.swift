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

enum AllChatLayoutEditorCoordinatorResult {
    case cancel
    case done(_ newSettings: AllChatLayoutSettings)
}

// MARK: View model

enum AllChatLayoutEditorViewModelResult {
    case cancel
    case done(_ newSettings: AllChatLayoutSettings)
    case addPinnedSpace
}

// MARK: View

struct AllChatLayoutEditorSection: Identifiable, Equatable {
    let id = UUID().uuidString
    let type: AllChatLayoutSectionType
    let name: String
    let image: UIImage
    var selected: Bool
}

struct AllChatLayoutEditorFilter: Identifiable, Equatable {
    let id = UUID().uuidString
    let type: AllChatLayoutFilterType
    let name: String
    let image: UIImage
    var selected: Bool
}

struct AllChatLayoutEditorSortingOption: Identifiable, Equatable {
    let id = UUID().uuidString
    let type: AllChatLayoutSortingType
    let name: String
    var selected: Bool
}

struct AllChatLayoutEditorViewState: BindableState {
    var sections: [AllChatLayoutEditorSection]
    var filters: [AllChatLayoutEditorFilter]
    var sortingOptions: [AllChatLayoutEditorSortingOption]
    var pinnedSpaces: [SpaceSelectorListItemData]
}

enum AllChatLayoutEditorViewAction {
    case tappedSectionItem(_ section: AllChatLayoutEditorSection)
    case tappedFilterItem(_ filter: AllChatLayoutEditorFilter)
    case tappedSortingOption(_ filter: AllChatLayoutEditorSortingOption)
    case addPinnedSpace
    case removePinnedSpace(_ item: SpaceSelectorListItemData)
    case cancel
    case done
}
