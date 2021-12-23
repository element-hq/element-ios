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
}

// MARK: View model

enum MatrixItemChooserStateAction {
    case loadingState(Bool)
    case updateError(Error?)
    case updateItems([MatrixListItemData])
    case updateSelection(Set<String>)
}

enum MatrixItemChooserViewModelResult {
    case cancel
    case done([String])
    case back
}

// MARK: View

struct MatrixListItemData {
    let id: String
    let avatar: AvatarInput
    let displayName: String?
    let detailText: String?
}

extension MatrixListItemData: Identifiable, Equatable {}

struct MatrixItemChooserViewState: BindableState {
    var title: String?
    var message: String?
    var emptyListMessage: String
    var items: [MatrixListItemData]
    var selectedItemIds: Set<String>
    var loading: Bool
    var error: String?
}

enum MatrixItemChooserViewAction {
    case searchTextChanged(String)
    case itemTapped(_ itemId: String)
    case done
    case cancel
    case back
}
