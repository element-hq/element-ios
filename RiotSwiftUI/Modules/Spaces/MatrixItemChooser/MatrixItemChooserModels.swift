//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
