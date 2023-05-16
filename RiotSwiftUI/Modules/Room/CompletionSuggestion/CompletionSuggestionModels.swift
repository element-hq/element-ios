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
