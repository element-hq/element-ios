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

enum MatrixItemChooserType {
    case room
    case people
    case ancestorsOf(String)
    case restrictedAllowedSpacesOf(String)
}

// MARK: View model

enum MatrixItemChooserViewModelResult {
    case cancel
    case done([String])
    case back
}

// MARK: View

enum MatrixListItemDataType {
    case user
    case room
    case space
}

struct MatrixListItemSectionData {
    let id: String
    let title: String?
    let infoText: String?
    let items: [MatrixListItemData]
    
    init(id: String = UUID().uuidString,
         title: String? = nil,
         infoText: String? = nil,
         items: [MatrixListItemData] = []) {
        self.id = id
        self.title = title
        self.infoText = infoText
        self.items = items
    }
}

extension MatrixListItemSectionData: Identifiable, Equatable { }

struct MatrixListItemData {
    let id: String
    let type: MatrixListItemDataType
    let avatar: AvatarInput
    let displayName: String?
    let detailText: String?
}

extension MatrixListItemData: Identifiable, Equatable { }

struct MatrixItemChooserSelectionHeader {
    var title: String
    var selectAllTitle: String
    var selectNoneTitle: String
}

struct MatrixItemChooserViewState: BindableState {
    var title: String?
    var message: String?
    var emptyListMessage: String
    var sections: [MatrixListItemSectionData]
    var itemCount: Int
    var selectedItemIds: Set<String>
    var loadingText: String?
    var loading: Bool
    var error: String?
    var selectionHeader: MatrixItemChooserSelectionHeader?
}

enum MatrixItemChooserViewAction {
    case searchTextChanged(String)
    case itemTapped(_ itemId: String)
    case done
    case cancel
    case back
    case selectAll
    case selectNone
}
