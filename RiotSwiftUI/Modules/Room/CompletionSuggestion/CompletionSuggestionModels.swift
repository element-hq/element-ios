//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum CompletionSuggestionViewAction {
    case selectedItem(CompletionSuggestionViewStateItem)
}

enum CompletionSuggestionViewModelResult {
    case selectedItemWithIdentifier(String)
}

enum CompletionSuggestionViewStateItem: Identifiable {
    case command(name: String, parametersFormat: String, description: String)
    case user(id: String, avatar: AvatarInputProtocol?, displayName: String?)

    var id: String {
        switch self {
        case .command(let name, _, _):
            return name
        case .user(let id, _, _):
            return id
        }
    }
}

struct CompletionSuggestionViewState: BindableState {
    var items: [CompletionSuggestionViewStateItem]
}
